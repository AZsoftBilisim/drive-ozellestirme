#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

Function StructureOfFillingIncomingOrder() Export
	
	Structure = New Structure;
	
	Structure.Insert("ReferenceOrder",               Undefined);
	Structure.Insert("Sender",                Undefined);
	Structure.Insert("CloseReceiptSchedule", Undefined);
	Structure.Insert("Warehouse",                      Undefined);
	Structure.Insert("ControlledLotReference",       Undefined);
	Structure.Insert("Premise",                  Undefined);
	Structure.Insert("ReceivingArea",                Undefined);
	Structure.Insert("IncomingDocumentDate",     Undefined);
	Structure.Insert("IncomingDocumentNumber",    Undefined);
	Structure.Insert("DateOfReceipt",            Undefined);
	Structure.Insert("BusinessOperation",      Undefined);
	
	Return Structure;
	
EndFunction

Function FillingStructureOfExpenseOrder() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Warehouse");
	ParametersStructure.Insert("Premise");
	ParametersStructure.Insert("Recipient");
	ParametersStructure.Insert("ShippingZone");
	ParametersStructure.Insert("TransportationJob");
	ParametersStructure.Insert("ShipmentReferences", New Array);
	ParametersStructure.Insert("BackgroundJob", False);

	Return ParametersStructure
	
EndFunction

#If Not MobileStandaloneServer Then

#Region AcceptanceCounters

//	Creates and returns a request for a list of acceptance orders.
//	
//	Parameters:
//		Warehouse - CatalogRef.Warehouses - link to the warehouse specified in the spending order.
//		DateOfReceipt - Date - date of receipt of goods.
//		ReceiptStatusFilter - String - string description of the filter according to the States of the acceptance orders.
//		RequestWithContracts - Boolean - indicates whether a condition for searching for orders among Contracts has been added to the request.
//		
//	Returns:
//		Query - request for a list of acceptance orders.
//	
Function RequestForOrderForAcceptance(Warehouse, DateOfReceipt, ReceiptStatusFilter, RequestWithContracts = True) Export
	
	UseGoodsReceiptNoteStatuses = GetFunctionalOption("UseGoodsReceiptNoteStatuses", New Structure("Warehouse", Warehouse));
	
	Query = New Query;
	QueryText =  
	"SELECT
	|	GoodsDueCurBalances.DocumentInflow AS DocumentInflow,
	|	GoodsDueCurBalances.Sender AS Sender,
	|	GoodsDueCurBalances.Products AS Products,
	|	GoodsDueCurBalances.Characteristic AS Characteristic,
	|	GoodsDueCurBalances.Purpose AS Purpose,
	|	GoodsDueCurBalances.ControlledLotReference AS ControlledLotReference,
	|	GoodsDueCurBalances.Warehouse AS Warehouse,
	|	GoodsDueCurBalances.GoodsReceiptNotesToRegisterBalance AS GoodsReceiptNotesToRegisterBalance,
	|	GoodsDueCurBalances.ToRegisterGoodsReceiptsBalance AS ToRegisterGoodsReceiptsBalance,
	|	GoodsDueCurBalances.AcceptsBalance AS AcceptsBalance,
	|	GoodsDueCurBalances.BusinessOperation AS EconomicOperationForFilter
	|INTO GoodsDueCurBalances
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(, Warehouse = &Warehouse) AS GoodsDueCurBalances
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	Warehouse,
	|	DocumentInflow,
	|	Sender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForExecutionOfOrdersTurnover.Products AS Products,
	|	GoodsForExecutionOfOrdersTurnover.Characteristic AS Characteristic,
	|	GoodsForExecutionOfOrdersTurnover.Purpose AS Purpose,
	|	GoodsForExecutionOfOrdersTurnover.ControlledLotReference AS ControlledLotReference,
	|	GoodsForExecutionOfOrdersTurnover.Warehouse AS Warehouse,
	|	GoodsForExecutionOfOrdersTurnover.DocumentInflow AS DocumentInflow,
	|	GoodsForExecutionOfOrdersTurnover.Sender AS Sender,
	|	GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterTurnover AS GoodsReceiptNotesToRegisterTurnover,
	|	GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterReceipt AS GoodsReceiptNotesToRegisterReceipt,
	|	GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterExpense AS GoodsReceiptNotesToRegisterExpense,
	|	GoodsForExecutionOfOrdersTurnover.AcceptsTurnover AS AcceptsTurnover,
	|	GoodsForExecutionOfOrdersTurnover.AcceptsReceipt AS AcceptsReceipt,
	|	GoodsForExecutionOfOrdersTurnover.AcceptsExpense AS AcceptsExpense
	|INTO GoodsForExecutionOfOrdersTurnover
	|FROM
	|	AccumulationRegister.GoodsToReceive.Turnovers(, , , &SpeedFilter) AS GoodsForExecutionOfOrdersTurnover
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	Warehouse,
	|	DocumentInflow,
	|	Sender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS DocumentInflow,
	|	GoodsToBeReceivedBalancesAsOfDate.Sender AS Sender,
	|	GoodsToBeReceivedBalancesAsOfDate.Products AS Products,
	|	GoodsToBeReceivedBalancesAsOfDate.Characteristic AS Characteristic,
	|	GoodsToBeReceivedBalancesAsOfDate.Purpose AS Purpose,
	|	GoodsToBeReceivedBalancesAsOfDate.ControlledLotReference AS ControlledLotReference,
	|	MIN(GoodsToBeReceivedBalancesAsOfDate.Series) AS Series,
	|	GoodsToBeReceivedBalancesAsOfDate.Warehouse AS Warehouse,
	|	GoodsToBeReceivedBalancesAsOfDate.BusinessOperation AS BusinessOperation,
	|	SUM(GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance) AS GoodsReceiptNotesToRegisterBalance,
	|	MAX(GoodsToBeReceivedBalancesAsOfDate.ToRegisterGoodsReceiptsBalance) AS ToRegisterGoodsReceiptsBalance,
	|	SUM(GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance) AS AcceptsBalance
	|INTO GoodsToBeReceivedBalancesAsOfDate
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			&DateOfReceipt,
	|			(Products, Characteristic, Purpose, ControlledLotReference, Warehouse, DocumentInflow, Sender, BusinessOperation) IN
	|				(SELECT
	|					FilterProductsForReceipt.Products,
	|					FilterProductsForReceipt.Characteristic,
	|					FilterProductsForReceipt.Purpose,
	|					FilterProductsForReceipt.ControlledLotReference,
	|					FilterProductsForReceipt.Warehouse,
	|					FilterProductsForReceipt.DocumentInflow,
	|					FilterProductsForReceipt.Sender,
	|					FilterProductsForReceipt.EconomicOperationForFilter AS BusinessOperation 
	|				FROM
	|					GoodsDueCurBalances AS FilterProductsForReceipt)) AS GoodsToBeReceivedBalancesAsOfDate
	|
	|GROUP BY
	|	GoodsToBeReceivedBalancesAsOfDate.Characteristic,
	|	GoodsToBeReceivedBalancesAsOfDate.DocumentInflow,
	|	GoodsToBeReceivedBalancesAsOfDate.Products,
	|	GoodsToBeReceivedBalancesAsOfDate.Sender,
	|	GoodsToBeReceivedBalancesAsOfDate.Warehouse,
	|	GoodsToBeReceivedBalancesAsOfDate.BusinessOperation,
	|	GoodsToBeReceivedBalancesAsOfDate.Purpose,
	|	GoodsToBeReceivedBalancesAsOfDate.ControlledLotReference
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	Warehouse,
	|	DocumentInflow,
	|	Sender,
	|	BusinessOperation";

	QueryText = QueryText + 
	"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";

	If RequestWithContracts Then
		QueryText = QueryText + 
		"SELECT
		|	NestedQuery.ReferenceOrder AS ReferenceOrder,
		|	NestedQuery.Sender AS Sender,
		|	NestedQuery.ControlledLotReferenceLotReference AS ControlledLotReferenceLotReference,
		|	NestedQuery.BusinessOperation AS BusinessOperation,
		|	MAX(CASE
		|			WHEN NestedQuery.IncomingDocumentNumber = """"
		|				THEN NestedQuery.Number
		|			ELSE NestedQuery.IncomingDocumentNumber
		|		END) AS Number,
		|	MAX(NestedQuery.Date) AS Date,
		|	MAX(NestedQuery.IncomingDocumentNumber) AS IncomingDocumentNumber,
		|	MAX(NestedQuery.IncomingDocumentDate) AS IncomingDocumentDate,
		|	MIN(NestedQuery.Overdelivery) AS Overdelivery,
		|	MIN(NestedQuery.State) AS State,
		|	CASE
		|		WHEN MIN(NestedQuery.State) = 1
		|			THEN VALUE(Enum.GoodsReceiptStates.DuringReceiving)
		|		WHEN MIN(NestedQuery.State) = 2
		|			THEN VALUE(Enum.GoodsReceiptStates.PendingReceiving)
		|		WHEN MIN(NestedQuery.State) = 3
		|			THEN VALUE(Enum.GoodsReceiptStates.Overdelivery)
		|		WHEN MIN(NestedQuery.State) = 4
		|			THEN VALUE(Enum.GoodsReceiptStates.PendingInvoiceRegistration)
		|		ELSE VALUE(Enum.GoodsReceiptStates.EmptyRef)
		|	END AS ReceiptState,
		|	NestedQuery.DocumentType AS DocumentType,
		|	CASE
		|		WHEN NOT NestedQuery.ReferenceOrder.Manager IS NULL
		|			THEN NestedQuery.ReferenceOrder.Manager
		|		ELSE NestedQuery.ReferenceOrder.EmployeeResponsible
		|	END AS EmployeeResponsible,
		|	&ResponsibleTitle AS ResponsibleTitle
		|INTO Lots
		|FROM
		|	(SELECT
		|		GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS ReferenceOrder,
		|		GoodsToBeReceivedBalancesAsOfDate.Sender AS Sender,
		|		ISNULL(GoodsToBeReceivedBalancesAsOfDate.ControlledLotReference.Lot, UNDEFINED) AS ControlledLotReferenceLotReference,
		|		GoodsToBeReceivedBalancesAsOfDate.BusinessOperation AS BusinessOperation,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
		|				THEN CAST(CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Number AS STRING(11))
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
		|				THEN CAST(CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.CounterpartyContracts).Number AS STRING(11))
		|			ELSE ISNULL(DocumentsRegistry.IBDocumentNumber, """")
		|		END AS Number,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
		|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Date
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
		|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.CounterpartyContracts).Date
		|			ELSE ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1, 1, 1))
		|		END AS Date,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
		|					OR GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
		|				THEN """"
		|			ELSE ISNULL(DocumentsRegistry.SourceDocumentNumber, """")
		|		END AS IncomingDocumentNumber,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
		|					OR GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
		|				THEN DATETIME(1, 1, 1)
		|			ELSE ISNULL(DocumentsRegistry.SourceDocumentDate, DATETIME(1, 1, 1))
		|		END AS IncomingDocumentDate,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
		|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Description
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
		|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.CounterpartyContracts).Description
		|			WHEN &ConditionsForUsingRegistryBusinessOperation
		|				THEN PRESENTATION(DocumentsRegistry.BusinessOperation)
		|			ELSE PRESENTATION(VALUETYPE(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow))
		|		END AS DocumentType,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance - GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance < 0
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS Overdelivery,
		|		CASE
		|			WHEN &ConditionStateDuringAcceptance
		|				THEN 1
		|			WHEN &ConditionStatePendingAcceptance
		|				THEN 2
		|			WHEN &ConditionStateReDelivery
		|				THEN 3
		|			WHEN ISNULL(GoodsToBeReceivedBalancesAsOfDate.ToRegisterGoodsReceiptsBalance, 0) <> 0
		|				THEN 4
		|			WHEN &ConditionStateTolerance
		|				THEN 6
		|			ELSE 404
		|		END AS State
		|	FROM
		|		GoodsToBeReceivedBalancesAsOfDate AS GoodsToBeReceivedBalancesAsOfDate
		|			LEFT JOIN GoodsDueCurBalances AS GoodsDueCurBalances
		|			ON GoodsToBeReceivedBalancesAsOfDate.Products = GoodsDueCurBalances.Products
		|				AND GoodsToBeReceivedBalancesAsOfDate.Characteristic = GoodsDueCurBalances.Characteristic
		|				AND GoodsToBeReceivedBalancesAsOfDate.Purpose = GoodsDueCurBalances.Purpose
		|				AND GoodsToBeReceivedBalancesAsOfDate.Sender = GoodsDueCurBalances.Sender
		|				AND GoodsToBeReceivedBalancesAsOfDate.Warehouse = GoodsDueCurBalances.Warehouse
		|				AND GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = GoodsDueCurBalances.DocumentInflow
		|			LEFT JOIN GoodsForExecutionOfOrdersTurnover AS GoodsForExecutionOfOrdersTurnover
		|			ON GoodsToBeReceivedBalancesAsOfDate.Products = GoodsForExecutionOfOrdersTurnover.Products
		|				AND GoodsToBeReceivedBalancesAsOfDate.Characteristic = GoodsForExecutionOfOrdersTurnover.Characteristic
		|				AND GoodsToBeReceivedBalancesAsOfDate.Purpose = GoodsForExecutionOfOrdersTurnover.Purpose
		|				AND GoodsToBeReceivedBalancesAsOfDate.Sender = GoodsForExecutionOfOrdersTurnover.Sender
		|				AND GoodsToBeReceivedBalancesAsOfDate.Warehouse = GoodsForExecutionOfOrdersTurnover.Warehouse
		|				AND GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = GoodsForExecutionOfOrdersTurnover.DocumentInflow
		|			LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|			ON GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = DocumentsRegistry.Ref
		|				AND (NOT DocumentsRegistry.AdditionalRecord)
		|	WHERE &ConditionForOrders
		|
		|UNION ALL
		|	
		|	SELECT
		|		CounterpartyContracts.Ref,
		|		CounterpartyContracts.Partner,
		|		CounterpartyContracts.BusinessOperation,
		|		UNDEFINED AS ControlledLotReferenceLotReference,
		|		CAST(CounterpartyContracts.Number AS STRING(11)),
		|		CounterpartyContracts.Date,
		|		"""",
		|		DATETIME(1, 1, 1),
		|		CounterpartyContracts.Description,
		|		FALSE,
		|		5
		|	FROM
		|		Catalog.CounterpartyContracts AS CounterpartyContracts
		|	WHERE
		|		CounterpartyContracts.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices)
		|		AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|		AND NOT CounterpartyContracts.DeletionMark) AS NestedQuery 
		|
		|GROUP BY
		|	NestedQuery.ReferenceOrder,
		|	NestedQuery.Sender,
		|	NestedQuery.ControlledLotReferenceLotReference,
		|	NestedQuery.BusinessOperation,
		|	NestedQuery.DocumentType,
		|	CASE
		|		WHEN NOT NestedQuery.ReferenceOrder.Manager IS NULL
		|			THEN NestedQuery.ReferenceOrder.Manager
		|		ELSE NestedQuery.ReferenceOrder.EmployeeResponsible
		|	END
		|
		|HAVING
		|	MIN(NestedQuery.State) IN (&ConditionByState)
		|INDEX BY
		|	ControlledLotReferenceLotReference";
	Else
		QueryText = QueryText + 
		"SELECT
		|	NestedQuery.ReferenceOrder AS ReferenceOrder,
		|	NestedQuery.Sender AS Sender,
		|	NestedQuery.ControlledLotReferenceLotReference AS ControlledLotReferenceLotReference,
		|	NestedQuery.BusinessOperation AS BusinessOperation,
		|	MAX(CASE
		|			WHEN NestedQuery.IncomingDocumentNumber = """"
		|				THEN NestedQuery.Number
		|			ELSE NestedQuery.IncomingDocumentNumber
		|		END) AS Number,
		|	MAX(NestedQuery.Date) AS Date,
		|	MAX(NestedQuery.IncomingDocumentNumber) AS IncomingDocumentNumber,
		|	MAX(NestedQuery.IncomingDocumentDate) AS IncomingDocumentDate,
		|	MIN(NestedQuery.Overdelivery) AS Overdelivery,
		|	MIN(NestedQuery.State) AS State,
		|	CASE
		|		WHEN MIN(NestedQuery.State) = 1
		|			THEN VALUE(Enum.GoodsReceiptStates.DuringReceiving)
		|		WHEN MIN(NestedQuery.State) = 2
		|			THEN VALUE(Enum.GoodsReceiptStates.PendingReceiving)
		|		WHEN MIN(NestedQuery.State) = 3
		|			THEN VALUE(Enum.GoodsReceiptStates.Overdelivery)
		|		WHEN MIN(NestedQuery.State) = 4
		|			THEN VALUE(Enum.GoodsReceiptStates.PendingInvoiceRegistration)
		|		ELSE VALUE(Enum.GoodsReceiptStates.EmptyRef)
		|	END AS ReceiptState,
		|	NestedQuery.DocumentType AS DocumentType,
		|	CASE
		|		WHEN NOT NestedQuery.ReferenceOrder.Manager IS NULL
		|			THEN NestedQuery.ReferenceOrder.Manager
		|		ELSE NestedQuery.ReferenceOrder.EmployeeResponsible
		|	END AS EmployeeResponsible,
		|	&ResponsibleTitle AS ResponsibleTitle
		|INTO Lots
		|FROM
		|	(SELECT
		|		GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS ReferenceOrder,
		|		GoodsToBeReceivedBalancesAsOfDate.Sender AS Sender,
		|		ISNULL(GoodsToBeReceivedBalancesAsOfDate.ControlledLotReference.Lot, UNDEFINED) AS ControlledLotReferenceLotReference,
		|		GoodsToBeReceivedBalancesAsOfDate.BusinessOperation AS BusinessOperation,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
		|				THEN CAST(CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Number AS STRING(11))
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
		|				THEN CAST(CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.CounterpartyContracts).Number AS STRING(11))
		|			ELSE ISNULL(DocumentsRegistry.IBDocumentNumber, """")
		|		END AS Number,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
		|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Date
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
		|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.CounterpartyContracts).Date
		|			ELSE ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1, 1, 1))
		|		END AS Date,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
		|					OR GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
		|				THEN """"
		|			ELSE ISNULL(DocumentsRegistry.SourceDocumentNumber, """")
		|		END AS IncomingDocumentNumber,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
		|					OR GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
		|				THEN DATETIME(1, 1, 1)
		|			ELSE ISNULL(DocumentsRegistry.SourceDocumentDate, DATETIME(1, 1, 1))
		|		END AS IncomingDocumentDate,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
		|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Description
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.DocumentInflow REFS Catalog.CounterpartyContracts
		|				THEN CAST(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS Catalog.CounterpartyContracts).Description
		|			WHEN &ConditionsForUsingRegistryBusinessOperation
		|				THEN PRESENTATION(DocumentsRegistry.BusinessOperation)
		|			ELSE PRESENTATION(VALUETYPE(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow))
		|		END AS DocumentType,
		|		CASE
		|			WHEN GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance - GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance < 0
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS Overdelivery,
		|		CASE
		|			WHEN &ConditionStateDuringAcceptance
		|				THEN 1
		|			WHEN &ConditionStatePendingAcceptance
		|				THEN 2
		|			WHEN &ConditionStateReDelivery
		|				THEN 3
		|			WHEN ISNULL(GoodsToBeReceivedBalancesAsOfDate.ToRegisterGoodsReceiptsBalance, 0) <> 0
		|				THEN 4
		|			WHEN &ConditionStateTolerance
		|				THEN 6
		|			ELSE 404
		|		END AS State
		|	FROM
		|		GoodsToBeReceivedBalancesAsOfDate AS GoodsToBeReceivedBalancesAsOfDate
		|			LEFT JOIN GoodsDueCurBalances AS GoodsDueCurBalances
		|			ON GoodsToBeReceivedBalancesAsOfDate.Products = GoodsDueCurBalances.Products
		|				AND GoodsToBeReceivedBalancesAsOfDate.Characteristic = GoodsDueCurBalances.Characteristic
		|				AND GoodsToBeReceivedBalancesAsOfDate.Purpose = GoodsDueCurBalances.Purpose
		|				AND GoodsToBeReceivedBalancesAsOfDate.Sender = GoodsDueCurBalances.Sender
		|				AND GoodsToBeReceivedBalancesAsOfDate.Warehouse = GoodsDueCurBalances.Warehouse
		|				AND GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = GoodsDueCurBalances.DocumentInflow
		|			LEFT JOIN GoodsForExecutionOfOrdersTurnover AS GoodsForExecutionOfOrdersTurnover
		|			ON GoodsToBeReceivedBalancesAsOfDate.Products = GoodsForExecutionOfOrdersTurnover.Products
		|				AND GoodsToBeReceivedBalancesAsOfDate.Characteristic = GoodsForExecutionOfOrdersTurnover.Characteristic
		|				AND GoodsToBeReceivedBalancesAsOfDate.Purpose = GoodsForExecutionOfOrdersTurnover.Purpose
		|				AND GoodsToBeReceivedBalancesAsOfDate.Sender = GoodsForExecutionOfOrdersTurnover.Sender
		|				AND GoodsToBeReceivedBalancesAsOfDate.Warehouse = GoodsForExecutionOfOrdersTurnover.Warehouse
		|				AND GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = GoodsForExecutionOfOrdersTurnover.DocumentInflow
		|			LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|			ON GoodsToBeReceivedBalancesAsOfDate.DocumentInflow = DocumentsRegistry.Ref
		|				AND (NOT DocumentsRegistry.AdditionalRecord)
		|	WHERE &ConditionForOrders) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.ReferenceOrder,
		|	NestedQuery.Sender,
		|	NestedQuery.ControlledLotReferenceLotReference,
		|	NestedQuery.BusinessOperation,
		|	NestedQuery.DocumentType,
		|	CASE
		|		WHEN NOT NestedQuery.ReferenceOrder.Manager IS NULL
		|			THEN NestedQuery.ReferenceOrder.Manager
		|		ELSE NestedQuery.ReferenceOrder.EmployeeResponsible
		|	END
		|
		|HAVING
		|	MIN(NestedQuery.State) IN (&ConditionByState)
		|INDEX BY
		|	ControlledLotReferenceLotReference";
	EndIf;
	
	QueryText = QueryText + 
	"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryText + 
	"SELECT
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	Table.Sender AS Sender,
	|	Table.ControlledLotReferenceLotReference <> UNDEFINED AS ThisIsAcceptanceOfControlledLotReference,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.Number AS Number,
	|	Table.Date AS Date,
	|	Table.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	Table.IncomingDocumentDate AS IncomingDocumentDate,
	|	Table.Overdelivery AS Overdelivery,
	|	Table.State AS State,
	|	Table.ReceiptState AS ReceiptState,
	|	Table.DocumentType AS DocumentType,
	|	Table.EmployeeResponsible AS EmployeeResponsible,
	|	Table.ResponsibleTitle AS ResponsibleTitle,
	|	&ControlledLotReferenceHeader AS ControlledLotReferenceHeader,
	|	CASE
	|		WHEN
	|			CASE
	|				WHEN Table.ControlledLotReferenceLotReference REFS Catalog.TermsOfPurchaseFromVendors
	|					THEN CAST(CAST(Table.ControlledLotReferenceLotReference AS Catalog.TermsOfPurchaseFromVendors).Number AS STRING(11))
	|				WHEN Table.ControlledLotReferenceLotReference REFS Catalog.CounterpartyContracts
	|					THEN CAST(CAST(Table.ControlledLotReferenceLotReference AS Catalog.CounterpartyContracts).Number AS STRING(11))
	|				ELSE ISNULL(DocumentsRegistry.IBDocumentNumber, """")
	|		END = """"
	|			THEN
	|				CASE
	|					WHEN Table.ControlledLotReferenceLotReference REFS Catalog.TermsOfPurchaseFromVendors
	|						THEN CAST(CAST(Table.ControlledLotReferenceLotReference AS Catalog.TermsOfPurchaseFromVendors).Number AS STRING(11))
	|					WHEN Table.ControlledLotReferenceLotReference REFS Catalog.CounterpartyContracts
	|						THEN CAST(CAST(Table.ControlledLotReferenceLotReference AS Catalog.CounterpartyContracts).Number AS STRING(11))
	|					ELSE ISNULL(DocumentsRegistry.IBDocumentNumber, """")
	|				END
	|			ELSE
	|				CASE
	|					WHEN Table.ControlledLotReferenceLotReference REFS Catalog.TermsOfPurchaseFromVendors
	|						THEN CAST(CAST(Table.ControlledLotReferenceLotReference AS Catalog.TermsOfPurchaseFromVendors).Number AS STRING(11))
	|					WHEN Table.ControlledLotReferenceLotReference REFS Catalog.CounterpartyContracts
	|						THEN CAST(CAST(Table.ControlledLotReferenceLotReference AS Catalog.CounterpartyContracts).Number AS STRING(11))
	|					ELSE ISNULL(DocumentsRegistry.IBDocumentNumber, """")
	|				END
	|	END AS LotNumber,
	|	CASE
	|		WHEN Table.ControlledLotReferenceLotReference REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(Table.ControlledLotReferenceLotReference AS Catalog.TermsOfPurchaseFromVendors).Date
	|		WHEN Table.ControlledLotReferenceLotReference REFS Catalog.CounterpartyContracts
	|			THEN CAST(Table.ControlledLotReferenceLotReference AS Catalog.CounterpartyContracts).Date
	|		ELSE ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1, 1, 1))
	|	END AS BatchDate,
	|	CASE
	|		WHEN Table.ControlledLotReferenceLotReference REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(Table.ControlledLotReferenceLotReference AS Catalog.TermsOfPurchaseFromVendors).Description
	|		WHEN Table.ControlledLotReferenceLotReference REFS Catalog.CounterpartyContracts
	|			THEN CAST(Table.ControlledLotReferenceLotReference AS Catalog.CounterpartyContracts).Description
	|		WHEN &TermsOfUseOfOperationOfRegisterLotReference
	|			THEN PRESENTATION(DocumentsRegistry.BusinessOperation)
	|		ELSE PRESENTATION(VALUETYPE(Table.ControlledLotReferenceLotReference))
	|	END AS DocumentTypeOfLotReference
	|FROM
	|	Lots AS Table
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON Table.ControlledLotReferenceLotReference = DocumentsRegistry.Ref
	|			AND (NOT DocumentsRegistry.AdditionalRecord)";
	
	Query.Text = QueryText;
	Query.Text = StrReplace(Query.Text, "&ResponsibleTitle", NStr("vi = '""Người quản lý""';
																	|ru = '""Менеджер""';
																	|en = '""Manager""'; fa = '""Manager""';
																	|it = '""Менеджер""';
																	|pl = '""Manager""';
																	|tr = '""Yönetici""'"));
	Query.SetParameter("ControlledLotReferenceHeader", NStr("vi = 'Lô hàng';
															|ru = 'Партия';
															|en = 'Lot'; fa = 'بچ';
															|it = 'Lot';
															|pl = 'Lot';
															|tr = 'Lot'"));
	
	ConditionsForUsingRegistryBusinessOperation = "VALUETYPE(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow) = TYPE(Document.OtherGoodsRecordingAsReceived)";
	ConditionsForUsingRegistryBusinessOperation = ConditionsForUsingRegistryBusinessOperation + "
			|				OR VALUETYPE(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow) = TYPE(Document.MovementOfProductsAndMaterials)";
	ReplacementText = StrReplace(ConditionsForUsingRegistryBusinessOperation,
		"GoodsToBeReceivedBalancesAsOfDate.DocumentInflow", "Table.ControlledLotReferenceLotReference");
	Query.Text = StrReplace(Query.Text,"&TermsOfUseOfOperationOfRegisterLotReference", ReplacementText);
	
	Query.Text = StrReplace(Query.Text,"&ConditionsForUsingRegistryBusinessOperation", ConditionsForUsingRegistryBusinessOperation);
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving <> 0 Then
		
		ConditionStatePendingAcceptance = "GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance > CASE
			|			WHEN GoodsToBeReceivedBalancesAsOfDate.Products.UnitOfMeasure.MeasuredValueType
			|					IN (&DimensionalTypesOfUnits)
			|				THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|					* ISNULL(GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterReceipt,0)
			|			ELSE 0
			|		END
			|	AND GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance = 0";
		
		ConditionStateReDelivery = "GoodsDueCurBalances.GoodsReceiptNotesToRegisterBalance < CASE
			|			WHEN GoodsToBeReceivedBalancesAsOfDate.Products.UnitOfMeasure.MeasuredValueType
			|					IN (&DimensionalTypesOfUnits)
			|				THEN - &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|					* ISNULL(GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterReceipt,0)
			|			ELSE 0
			|		END
			|	AND GoodsDueCurBalances.AcceptsBalance = 0";
		
		ConditionStateDuringAcceptance = "GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance > 0";
		
		ConditionStateTolerance = "GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance <= CASE
			|			WHEN GoodsToBeReceivedBalancesAsOfDate.Products.UnitOfMeasure.MeasuredValueType IN(&DimensionalTypesOfUnits)
			|				THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|					* ISNULL(GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterReceipt, 0)
			|			ELSE 0
			|		END
			|		AND GoodsDueCurBalances.GoodsReceiptNotesToRegisterBalance >= CASE
			|			WHEN GoodsToBeReceivedBalancesAsOfDate.Products.UnitOfMeasure.MeasuredValueType IN(&DimensionalTypesOfUnits)
			|				THEN -&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|					* ISNULL(GoodsForExecutionOfOrdersTurnover.GoodsReceiptNotesToRegisterReceipt, 0)
			|			ELSE 0
			|		END
			|		AND GoodsDueCurBalances.AcceptsBalance = 0";
		
		Query.Text = StrReplace(Query.Text,"&ConditionStatePendingAcceptance", 	ConditionStatePendingAcceptance);
		Query.Text = StrReplace(Query.Text,"&ConditionStateReDelivery", 		ConditionStateReDelivery);
		Query.Text = StrReplace(Query.Text,"&ConditionStateDuringAcceptance", 	ConditionStateDuringAcceptance);
		Query.Text = StrReplace(Query.Text,"&ConditionStateTolerance",ConditionStateTolerance);
		
		SpeedFilter =
		"				(Products, Characteristic, Purpose, ControlledLotReference, Warehouse, DocumentInflow, Sender) IN
		|					(SELECT
		|						GoodsDueCurBalances.Products,
		|						GoodsDueCurBalances.Characteristic,
		|						GoodsDueCurBalances.Purpose,
		|						GoodsDueCurBalances.ControlledLotReference,
		|						GoodsDueCurBalances.Warehouse,
		|						GoodsDueCurBalances.DocumentInflow,
		|						GoodsDueCurBalances.Sender
		|					FROM
		|						GoodsDueCurBalances AS GoodsDueCurBalances)";
		
		Query.Text = StrReplace(Query.Text,"&SpeedFilter", SpeedFilter);
		
	Else
		
		ConditionStatePendingAcceptance = "GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance > 0
											|	AND GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance = 0";
		
		ConditionStateReDelivery = "GoodsDueCurBalances.GoodsReceiptNotesToRegisterBalance < 0
											|	AND GoodsDueCurBalances.AcceptsBalance = 0";
		
		ConditionStateDuringAcceptance = "GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance > 0";
		
		Query.Text = StrReplace(Query.Text,"&ConditionStateReDelivery", ConditionStateReDelivery);
		Query.Text = StrReplace(Query.Text,"&ConditionStatePendingAcceptance", ConditionStatePendingAcceptance);
		Query.Text = StrReplace(Query.Text,"&ConditionStateDuringAcceptance", ConditionStateDuringAcceptance);
		Query.Text = StrReplace(Query.Text,"&ConditionStateTolerance","FALSE");
		
		Query.Text = StrReplace(Query.Text,"&SpeedFilter", "FALSE");
		
	EndIf;

	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	
	Query.SetParameter("Warehouse", Warehouse);
	If ValueIsFilled(DateOfReceipt) Then
		Query.SetParameter("DateOfReceipt", EndOfDay(DateOfReceipt)); 
	Else
		Query.SetParameter("DateOfReceipt", DateOfReceipt); 
	EndIf;
	
	ReceiptStatuses = New Array;
	
	MatchingIndexStates = New Map;
	
	MatchingIndexStates.Insert(Enums.GoodsReceiptStates.DuringReceiving, 1);
	MatchingIndexStates.Insert(Enums.GoodsReceiptStates.PendingReceiving, 2);
	MatchingIndexStates.Insert(Enums.GoodsReceiptStates.Overdelivery, 3);
	MatchingIndexStates.Insert(Enums.GoodsReceiptStates.PendingInvoiceRegistration, 4);
	MatchingIndexStates.Insert(Enums.GoodsReceiptStates.EmptyRef(),5);

	If ReceiptStatusFilter = "All" Then
		For Each EnumerationValue In Enums.GoodsReceiptStates Do 
			ReceiptStatuses.Add(MatchingIndexStates.Get(EnumerationValue));	
		EndDo;
		ReceiptStatuses.Add(MatchingIndexStates.Get(Enums.GoodsReceiptStates.EmptyRef()));
	ElsIf ReceiptStatusFilter = "AllToReceiving" Then
		ReceiptStatuses.Add(MatchingIndexStates.Get(Enums.GoodsReceiptStates.PendingReceiving));
		ReceiptStatuses.Add(MatchingIndexStates.Get(Enums.GoodsReceiptStates.DuringReceiving));
		ReceiptStatuses.Add(MatchingIndexStates.Get(Enums.GoodsReceiptStates.EmptyRef()));
	Else
		ReceiptStatuses.Add(MatchingIndexStates.Get(Enums.GoodsReceiptStates.PendingReceiving));
	EndIf;
	
	ReceiptStatuses.Add(404);
	
	Query.SetParameter("ConditionByState", ReceiptStatuses);
	
	Return Query;
	
EndFunction

Function PutAwayList() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	NestedQuery.Products AS Products,
		|	NestedQuery.SKU AS SKU,
		|	NestedQuery.WarehouseGroupOfProducts AS WarehouseGroupOfProducts,
		|	NestedQuery.Characteristic AS Characteristic,
		|	NestedQuery.Package AS Package,
		|	NestedQuery.WarehouseGroupOfPackages AS WarehouseGroupOfPackages,
		|	NestedQuery.NumberOfPackages AS NumberOfPackages,
		|	NestedQuery.TakePlaces AS TakePlaces,
		|	NestedQuery.ErrorInPackaging AS ErrorInPackaging,
		|	NestedQuery.ErrorInTheStorageArea AS ErrorInTheStorageArea,
		|	NestedQuery.ItemError AS ItemError,
		|	NestedQuery.Series AS Series,
		|	NestedQuery.Purpose AS Purpose,
		|	NestedQuery.Products AS Ref
		|FROM
		|	(SELECT
		|		GoodsInStorageBinsBalance.Products AS Products,
		|		GoodsInStorageBinsBalance.Products.SKU AS SKU,
		|		GoodsInStorageBinsBalance.Products.WarehouseGroup AS WarehouseGroupOfProducts,
		|		GoodsInStorageBinsBalance.Characteristic AS Characteristic,
		|		CASE
		|			WHEN GoodsInStorageBinsBalance.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|				THEN CASE
		|						WHEN GoodsInStorageBinsBalance.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|							THEN GoodsInStorageBinsBalance.Products.UnitOfMeasure
		|						ELSE GoodsInStorageBinsBalance.Package
		|					END
		|			ELSE GoodsInStorageBinsBalance.Products.UnitOfMeasure
		|		END AS Package,
		|		CASE
		|			WHEN GoodsInStorageBinsBalance.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|				THEN ISNULL(GoodsInStorageBinsBalance.Package.WarehouseGroup, VALUE(Catalog.WarehousePackageGroups.EmptyRef))
		|			ELSE VALUE(Catalog.WarehousePackageGroups.EmptyRef)
		|		END AS WarehouseGroupOfPackages,
		|		GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance AS NumberOfPackages,
		|		GoodsInStorageBinsBalance.ForPickingBalance AS TakePlaces,
		|		CASE
		|			WHEN GoodsInStorageBinsBalance.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|						AND NOT GoodsInStorageBinsBalance.Package.Dimensionless
		|						AND (GoodsInStorageBinsBalance.Package.Height = 0
		|							OR GoodsInStorageBinsBalance.Package.Width = 0
		|							OR GoodsInStorageBinsBalance.Package.Depth = 0
		|							OR GoodsInStorageBinsBalance.Package.VolumeM3 = 0
		|								AND ISNULL(GoodsInStorageBinsBalance.Products.WarehouseGroup.LimitByVolume, TRUE))
		|					OR GoodsInStorageBinsBalance.Package.Weight = 0
		|						AND ISNULL(GoodsInStorageBinsBalance.Products.WarehouseGroup.LimitByWeight, TRUE)
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS ErrorInPackaging,
		|		CASE
		|			WHEN GoodsInStorageBinsBalance.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				THEN ISNULL(GoodsInStorageBinsBalance.Products.WarehouseGroup.LimitByWeight, TRUE)
		|							AND NOT GoodsInStorageBinsBalance.Products.WeightUse
		|						OR ISNULL(GoodsInStorageBinsBalance.Products.WarehouseGroup.LimitByVolume, TRUE)
		|							AND NOT GoodsInStorageBinsBalance.Products.VolumeUse
		|			ELSE FALSE
		|		END AS ItemError,
		|		CASE
		|			WHEN GoodsPlacementRules.StorageArea IS NULL
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS ErrorInTheStorageArea,
		|		GoodsInStorageBinsBalance.Series AS Series,
		|		GoodsInStorageBinsBalance.Purpose AS Purpose
		|	FROM
		|		AccumulationRegister.GoodsInStorageBins.Balance(, Cell = &ReceivingArea) AS GoodsInStorageBinsBalance
		|			LEFT JOIN InformationRegister.GoodsPlacementRules AS GoodsPlacementRules
		|			ON GoodsInStorageBinsBalance.Products.WarehouseGroup = GoodsPlacementRules.WarehouseGroupOfProducts
		|				AND (CASE
		|					WHEN GoodsInStorageBinsBalance.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|						THEN ISNULL(GoodsInStorageBinsBalance.Package.WarehouseGroup, VALUE(Catalog.WarehousePackageGroups.EmptyRef))
		|					ELSE VALUE(Catalog.WarehousePackageGroups.EmptyRef)
		|				END = GoodsPlacementRules.WarehouseGroupOfPackages)
		|				AND GoodsInStorageBinsBalance.Cell.Owner = GoodsPlacementRules.Warehouse
		|				AND GoodsInStorageBinsBalance.Cell.Premise = GoodsPlacementRules.Premise) AS NestedQuery
		|WHERE
		|	NestedQuery.NumberOfPackages > 0";
	
	Return Query;
	
EndFunction

#EndRegion

#Region ShippingCounters

//	Creates and returns a request for a list of acceptance orders.
//	
//	Parameters:
//		Warehouse - CatalogRef.Warehouses - 
//		
//	Returns:
//		Query - request for a list of acceptance orders.
//	
Function RequestOrderForShipment(Warehouse) Export 
	
	Query = New Query;
	
	// Caching the current parameters
	ShipmentReferenceParameters = New Structure("Warehouse, TransportationJob, DateOfShipment");
	FillPropertyValues(ShipmentReferenceParameters, Query.Parameters);
	ShipmentReferenceParameters.Insert("ShowDetailsShipment", False);
	ShipmentReferenceParameters = New FixedStructure(ShipmentReferenceParameters);
	
	QueryText = "";
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving <> 0 Then
		
		QueryText = QueryText + "
		|SELECT
		|	GoodsForShipmentTurnover.DocumentShipments AS DocumentShipments,
		|	GoodsForShipmentTurnover.Products     AS Products,
		|	GoodsForShipmentTurnover.Characteristic   AS Characteristic,
		|	GoodsForShipmentTurnover.Purpose       AS Purpose,
		|	GoodsForShipmentTurnover.Series            AS Series,
		|	GoodsForShipmentTurnover.Warehouse            AS Warehouse,
		|	GoodsForShipmentTurnover.ToShipReceipt  AS Count
		|
		|INTO GoodsForShipmentTurnover
		|FROM
		|	AccumulationRegister.GoodsForIssue.Turnovers(
		|			,
		|			,
		|			,
		|			&ConnectionConditionRevolutions) AS GoodsForShipmentTurnover
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
	If WarehousesServer.StartShipmentOnceDeliveryOrderIsCreated(Warehouse) Then
		
		QueryText = QueryText + 
		"SELECT DISTINCT
		|	StatesAndDetailsOfDelivery.ReferenceOrder AS DocumentShipments,
		|	StatesAndDetailsOfDelivery.RecipientSender AS Recipient
		|INTO TTOrdersWithDeliveryByTasks
		|FROM
		|	InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
		|		LEFT JOIN InformationRegister.GoodsToDeliver AS RefusalOfTransportation
		|		ON (RefusalOfTransportation.TransportationJob = VALUE(Document.TransportationJob.EmptyRef))
		|			AND StatesAndDetailsOfDelivery.Warehouse = RefusalOfTransportation.Warehouse
		|			AND (RefusalOfTransportation.ReferenceOrder = StatesAndDetailsOfDelivery.ReferenceOrder)
		|WHERE
		|	StatesAndDetailsOfDelivery.Warehouse = &Warehouse
		|	AND StatesAndDetailsOfDelivery.DeliveryMethod IN(&TransportMethods)
		|	AND RefusalOfTransportation.ReferenceOrder IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	NestedQuery.DocumentShipments AS DocumentShipments,
		|	NestedQuery.Recipient AS Recipient,
		|	MIN(NestedQuery.State) AS State
		|INTO TTOrdersEEU
		|FROM
		|	(SELECT
		|		ReferencesToShip.DocumentShipments AS DocumentShipments,
		|		ReferencesToShip.Recipient AS Recipient,
		|		ReferencesToShip.Products AS Products,
		|		ReferencesToShip.Characteristic AS Characteristic,
		|		ReferencesToShip.Purpose AS Purpose,
		|		ReferencesToShip.Series AS Series,
		|		CASE
		|			WHEN &PendingPicking
		|				THEN 0
		|			WHEN ReferencesToShip.AssemblyInProgressBalance <> 0
		|				THEN 1
		|			WHEN ReferencesToShip.AssembledBalance <> 0
		|				THEN 2
		|			WHEN ReferencesToShip.ToRegisterBalance <> 0
		|				THEN 3
		|			ELSE 404
		|		END AS State
		|	FROM
		|		AccumulationRegister.GoodsForIssue.Balance(&DateOfShipment, Warehouse = &Warehouse) AS ReferencesToShip
		|	WHERE &ConditionGoodsForSelection) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.DocumentShipments,
		|	NestedQuery.Recipient
		|
		|INDEX BY
		|	DocumentShipments
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TransportationTask.Ref AS Ref,
		|	TransportationTask.ReferenceOrder AS ReferenceOrder,
		|	TransportationTask.RecipientSender AS RecipientSender
		|INTO TTTransportTaskSelection
		|FROM
		|	Document.TransportationJob.References AS TransportationTask
		|WHERE
		|	TransportationTask.Ref.Posted
		|	AND TransportationTask.Warehouse = &Warehouse
		|	AND TransportationTask.Ref.Status IN (VALUE(Enum.StatusesOfTransportationJobs.ToLoad))
		|
		|INDEX BY
		|	ReferenceOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	VALUETYPE(TransportationJobs.ReferenceOrder) AS DocumentType,
		|	TransportationJobs.ReferenceOrder AS ReferenceOrder,
		|	TransportationJobs.Ref AS TransportationJob,
		|	TransportationJobs.ReferenceOrder.Number AS Number,
		|	TransportationJobs.ReferenceOrder.Date AS Date,
		|	TransportationJobs.RecipientSender AS Recipient,
		|	MIN(TTOrdersEEU.State) AS ShipmentStatus,
		|	CASE
		|		WHEN MIN(TTOrdersEEU.State) = 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN MIN(TTOrdersEEU.State) = 1
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN MIN(TTOrdersEEU.State) = 2
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		WHEN MIN(TTOrdersEEU.State) = 3
		|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END AS State,
		|	1 AS PictureIndex
		|FROM
		|	TTTransportTaskSelection AS TransportationJobs
		|		INNER JOIN TTOrdersEEU AS TTOrdersEEU
		|		ON (TTOrdersEEU.DocumentShipments = TransportationJobs.ReferenceOrder)
		|
		|GROUP BY
		|	TransportationJobs.ReferenceOrder,
		|	TransportationJobs.ReferenceOrder.Number,
		|	TransportationJobs.ReferenceOrder.Date,
		|	TransportationJobs.RecipientSender,
		|	TransportationJobs.Ref
		|
		|HAVING
		|	CASE
		|		WHEN MIN(TTOrdersEEU.State) = 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN MIN(TTOrdersEEU.State) = 1
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN MIN(TTOrdersEEU.State) = 2
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		WHEN MIN(TTOrdersEEU.State) = 3
		|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END IN (&States1)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN ReferencesToShip.DocumentShipments REFS Document.MovementOfProductsAndMaterials
		|			THEN PRESENTATION(ISNULL(DocumentsRegistry.BusinessOperation, VALUETYPE(ReferencesToShip.DocumentShipments)))
		|		ELSE 
		|	VALUETYPE(ReferencesToShip.DocumentShipments)
		|	END
		|,
		|	ReferencesToShip.DocumentShipments,
		|	VALUE(Document.TransportationJob.EmptyRef),
		|	ISNULL(DocumentsRegistry.IBDocumentNumber, """"),
		|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1,1,1)),
		|	ReferencesToShip.Recipient,
		|	ReferencesToShip.State AS ShipmentStatus,
		|	CASE
		|		WHEN ReferencesToShip.State = 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN ReferencesToShip.State = 1
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN ReferencesToShip.State = 2
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		WHEN ReferencesToShip.State = 3
		|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END,
		|	0
		|FROM
		|	TTOrdersEEU AS ReferencesToShip
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON ReferencesToShip.DocumentShipments = DocumentsRegistry.Ref
		|			AND (NOT DocumentsRegistry.AdditionalRecord)
		|		LEFT JOIN TTOrdersWithDeliveryByTasks AS TTOrdersWithDeliveryByTasks
		|		ON ReferencesToShip.DocumentShipments = TTOrdersWithDeliveryByTasks.DocumentShipments
		|WHERE
		|	TTOrdersWithDeliveryByTasks.DocumentShipments IS NULL
		|	AND CASE
		|			WHEN ReferencesToShip.State = 0
		|				THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|			WHEN ReferencesToShip.State = 1
		|				THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|			WHEN ReferencesToShip.State = 2
		|				THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|			WHEN ReferencesToShip.State = 3
		|				THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
		|			ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|		END IN (&States1)";
		
		TransportMethods = GoodsDeliveryClientServer.DeliveryMethodsToCustomerWithOurParticipation(
			GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"));
		
		Query.SetParameter("TransportMethods", TransportMethods);
					
	Else
		QueryText = QueryText + "
		|SELECT DISTINCT
		|	NestedQuery.DocumentShipments AS ReferenceOrder,
		|	NestedQuery.Recipient AS Recipient,
		|	MIN(NestedQuery.State) AS ShipmentStatus,
		|	CASE
		|		WHEN MIN(NestedQuery.State) = 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN MIN(NestedQuery.State) = 1
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN MIN(NestedQuery.State) = 2
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		WHEN MIN(NestedQuery.State) = 3
		|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END AS State
		|INTO OrdersAndStates
		|FROM
		|	(SELECT
		|		ReferencesToShip.DocumentShipments AS DocumentShipments,
		|		ReferencesToShip.Recipient AS Recipient,
		|		ReferencesToShip.Products AS Products,
		|		ReferencesToShip.Characteristic AS Characteristic,
		|		ReferencesToShip.Purpose AS Purpose,
		|		ReferencesToShip.Series AS Series,
		|		CASE
		|			WHEN &PendingPicking
		|				THEN 0
		|			WHEN ReferencesToShip.AssemblyInProgressBalance <> 0
		|				THEN 1
		|			WHEN ReferencesToShip.AssembledBalance <> 0
		|				THEN 2
		|			WHEN ReferencesToShip.ToRegisterBalance <> 0
		|				THEN 3
		|			ELSE 404
		|		END AS State
		|	FROM
		|		AccumulationRegister.GoodsForIssue.Balance(&DateOfShipment, Warehouse = &Warehouse) AS ReferencesToShip
		|	WHERE &ConditionGoodsForSelection) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.DocumentShipments,
		|	NestedQuery.Recipient
		|
		|HAVING
		|	CASE
		|		WHEN MIN(NestedQuery.State) = 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN MIN(NestedQuery.State) = 1
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN MIN(NestedQuery.State) = 2
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		WHEN MIN(NestedQuery.State) = 3
		|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END IN (&States1)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrdersAndStates.ReferenceOrder AS ReferenceOrder,
		|	OrdersAndStates.Recipient AS Recipient,
		|	ISNULL(DocumentsRegistry.IBDocumentNumber, """") AS Number,
		|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1,1,1)) AS Date,
		|	CASE
		|		WHEN OrdersAndStates.ReferenceOrder REFS Document.MovementOfProductsAndMaterials
		|			THEN PRESENTATION(ISNULL(DocumentsRegistry.BusinessOperation, VALUETYPE(OrdersAndStates.ReferenceOrder)))
		|		ELSE 
		|	VALUETYPE(OrdersAndStates.ReferenceOrder)
		|	END
		| 	AS DocumentType,
		|	OrdersAndStates.ShipmentStatus,
		|	OrdersAndStates.State,
		|	CASE
		|		WHEN NOT OrdersAndStates.ReferenceOrder.Manager IS NULL
		|			THEN OrdersAndStates.ReferenceOrder.Manager
		|		ELSE OrdersAndStates.ReferenceOrder.EmployeeResponsible
		|	END AS EmployeeResponsible,
		|	0 AS PictureIndex,
		|	&ResponsibleTitle AS ResponsibleTitle
		|FROM
		|	OrdersAndStates AS OrdersAndStates
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON OrdersAndStates.ReferenceOrder = DocumentsRegistry.Ref
		|			AND (NOT DocumentsRegistry.AdditionalRecord)";
	EndIf; 
	
	If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving <> 0 Then
		
		PendingPicking = 
		"		&IssueInvoicesFirst
		|			AND CASE
		|				WHEN ReferencesToShip.ToShipBalance - ReferencesToShip.ToRegisterBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance >= 0
		|					THEN ReferencesToShip.ToShipBalance - ReferencesToShip.ToRegisterBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance
		|				ELSE -(ReferencesToShip.ToShipBalance - ReferencesToShip.ToRegisterBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance)
		|			END > CASE
		|				WHEN ReferencesToShip.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|					THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 * GoodsForShipmentTurnover.Count
		|				ELSE 0
		|			END
		|		OR NOT &IssueInvoicesFirst
		|			AND CASE
		|				WHEN ReferencesToShip.ToShipBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance >= 0
		|					THEN ReferencesToShip.ToShipBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance
		|				ELSE -(ReferencesToShip.ToShipBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance)
		|			END > CASE
		|				WHEN ReferencesToShip.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|					THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 * GoodsForShipmentTurnover.Count
		|				ELSE 0
		|			END";
				
		ConditionGoodsForSelection = "
		|		INNER JOIN GoodsForShipmentTurnover AS GoodsForShipmentTurnover
		|		ON ReferencesToShip.DocumentShipments = GoodsForShipmentTurnover.DocumentShipments
		|			AND ReferencesToShip.Products = GoodsForShipmentTurnover.Products
		|			AND ReferencesToShip.Characteristic = GoodsForShipmentTurnover.Characteristic
		|			AND ReferencesToShip.Purpose = GoodsForShipmentTurnover.Purpose
		|			AND ReferencesToShip.Series = GoodsForShipmentTurnover.Series
		|			AND ReferencesToShip.Warehouse = GoodsForShipmentTurnover.Warehouse
		|WHERE
		|
		|	(ReferencesToShip.ToRegisterBalance >
		|		CASE
		|			WHEN ReferencesToShip.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|				THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 * GoodsForShipmentTurnover.Count
		|					ELSE 0
		|		END
		|
		|	OR ReferencesToShip.AssemblyInProgressBalance <> 0
		|	OR ReferencesToShip.AssembledBalance <> 0
		|	OR (&PendingPicking))
		|	&ConditionForOrders";
		
		ConditionGoodsForSelection = StrReplace(ConditionGoodsForSelection,"&PendingPicking", PendingPicking);
		
		QueryText = StrReplace(QueryText,"WHERE &ConditionGoodsForSelection", ConditionGoodsForSelection);
		QueryText = StrReplace(QueryText,"&PendingPicking", PendingPicking);
		Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
		Query.SetParameter("DimensionalTypesOfUnits", Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Else
		
		PendingPicking = 
		"&IssueInvoicesFirst
		|			AND ReferencesToShip.ToShipBalance - ReferencesToShip.ToRegisterBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance > 0
		|		OR NOT &IssueInvoicesFirst
		|			AND ReferencesToShip.ToShipBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance > 0";
		
		ConditionGoodsForSelection = 
		"WHERE 
		|	((ReferencesToShip.ToRegisterBalance <> 0
		|			OR (&PendingPicking)
		|			OR ReferencesToShip.AssemblyInProgressBalance <> 0
		|			OR ReferencesToShip.AssembledBalance <> 0)
		|			&ConditionForOrders)";
		
		ConditionGoodsForSelection = StrReplace(ConditionGoodsForSelection,"&PendingPicking", PendingPicking);
		
		QueryText = StrReplace(QueryText,"WHERE &ConditionGoodsForSelection", ConditionGoodsForSelection);
		QueryText = StrReplace(QueryText,"&PendingPicking", PendingPicking);
		
	EndIf;
	
	ConnectionConditionRevolutions = "Warehouse = &Warehouse"; 
	QueryText = StrReplace(QueryText,"&ResponsibleTitle", NStr("vi = '""Người quản lý""';
																|ru = '""Менеджер""';
																|en = '""Manager""'; fa = '""Manager""';
																|it = '""Менеджер""';
																|pl = '""Manager""';
																|tr = '""Yönetici""'"));
	QueryText = StrReplace(QueryText,"&ConnectionConditionRevolutions", ConnectionConditionRevolutions);
	
	Query.Text = QueryText;
	Return Query;
	
EndFunction

// Generates a list of orders for shipment or acceptance.
//  Parameters:
//   DocumentType - Number - if 1, then receive receipt data, otherwise I will receive shipment data. 
//   ReferenceOrder - DefinedType.ShipmentReferenceOrder,DefinedType.ReceiptReferenceOrder - ReferenceOrder
//   ControlledLotReference - CatalogRef.ControlledLots - Party.
//  Returns:
//   ValueTable - table with fields:
//    * Products - See AccumulationRegister.GoodsToReceive.Products
//    * Characteristic - See AccumulationRegister.GoodsToReceive.Characteristic
//    * Purpose - See AccumulationRegister.GoodsToReceive.Purpose
//    * Series - See AccumulationRegister.GoodsToReceive.Series
//    * Warehouse - See AccumulationRegister.GoodsToReceive.Warehouse
//    * NumberOfPackages - Number - The Balance to be shipped or received.
//    * SKU - See Catalog.Products.SKU
//    * Package - See Catalog.Products.UnitOfMeasure
Function ListOfGoodsForShipmentAcceptance(DocumentType, ReferenceOrder, ControlledLotReference = Undefined) Export
	
	If DocumentType = 1 Then 
								
		Query = New Query;
		Query.Text = 
		"SELECT
		|	GoodsToReceiveBalance.Products AS Products,
		|	GoodsToReceiveBalance.Products.SKU AS SKU,
		|	GoodsToReceiveBalance.Characteristic AS Characteristic,
		|	GoodsToReceiveBalance.Purpose AS Purpose,
		|	GoodsToReceiveBalance.Series AS Series,
		|	GoodsToReceiveBalance.Warehouse AS Warehouse,
		|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance AS NumberOfPackages,
		|	GoodsToReceiveBalance.Products.UnitOfMeasure AS Package
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow = &DocumentInflow
		// If the acceptance order was issued for a specific batch (for example, the movement of blocked goods,
		// then you need to accept it, if not, then all goods orders.
		|		AND (ControlledLotReference = &ControlledLotReference
		|			OR ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef))) AS GoodsToReceiveBalance
		|WHERE
		|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance > 0";
			
		Query.SetParameter("DocumentInflow", ReferenceOrder);
		Query.SetParameter("ControlledLotReference", ControlledLotReference);
			
		Return Query.Execute().Unload();
		
	Else
				
		Query = New Query;
		Query.Text = 
		"SELECT
		|	GoodsForIssueBalance.Warehouse AS Warehouse,
		|	GoodsForIssueBalance.Recipient AS Recipient,
		|	GoodsForIssueBalance.DocumentShipments AS DocumentShipments,
		|	GoodsForIssueBalance.Products AS Products,
		|	GoodsForIssueBalance.Products.SKU AS SKU,
		|	GoodsForIssueBalance.Characteristic AS Characteristic,
		|	GoodsForIssueBalance.Purpose AS Purpose,
		|	GoodsForIssueBalance.Series AS Series,
		|	GoodsForIssueBalance.ToShipBalance AS NumberOfPackages,
		|	GoodsForIssueBalance.Products.UnitOfMeasure AS Package
		|FROM
		|	AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments = &DocumentShipments) AS GoodsForIssueBalance
		|WHERE
		|	GoodsForIssueBalance.ToShipBalance > 0";
		
		Query.SetParameter("DocumentShipments", ReferenceOrder);
		
		Return Query.Execute().Unload();
		
	EndIf;
	
EndFunction	
		
#EndRegion

#EndIf

Function BatchAccountingPolicy(ProductKind, Warehouse) Export
	
	ConnectionFieldValues = New Structure();
	ConnectionFieldValues.Insert("Warehouse", Warehouse);
	
#If Not MobileStandaloneServer Then
	SeriesUseSettings = Catalogs.ItemKinds.SeriesUseSettings(ProductKind,,ConnectionFieldValues);
#Else
	SeriesUseSettings = MobileWarehouseKeeperWorkspace.SeriesUseSettings(ProductKind,,ConnectionFieldValues);
#EndIf
	
	Return SeriesUseSettings.BatchAccountingPolicy;

EndFunction

#Region AcceptanceCounters

Function PutAwayJobList() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DocumentGoodsPickingPlacement.Ref AS Ref,
		|	DocumentGoodsPickingPlacement.DeletionMark AS DeletionMark,
		|	DocumentGoodsPickingPlacement.Number AS Number,
		|	DocumentGoodsPickingPlacement.Date AS Date,
		|	DocumentGoodsPickingPlacement.Posted AS Posted,
		|	DocumentGoodsPickingPlacement.OperationKind AS OperationKind,
		|	DocumentGoodsPickingPlacement.ReceivingArea AS ReceivingArea,
		|	DocumentGoodsPickingPlacement.Performer AS Performer,
		|	DocumentGoodsPickingPlacement.Comment AS Comment,
		|	DocumentGoodsPickingPlacement.Status AS Status,
		|	DocumentGoodsPickingPlacement.VolumePutAway AS VolumePutAway,
		|	DocumentGoodsPickingPlacement.WeightPlacement AS WeightPlacement,
		|	&PerformerTitle AS PerformerTitle
		|FROM
		|	Document.GoodsPickingPlacement AS DocumentGoodsPickingPlacement
		|WHERE
		|	DocumentGoodsPickingPlacement.ReceivingArea = &ReceivingArea
		|	AND DocumentGoodsPickingPlacement.Warehouse = &Warehouse
		|	AND &ConditionExecutor
		|	AND &ConditionPremises
		|	AND DocumentGoodsPickingPlacement.Posted
		|	AND NOT DocumentGoodsPickingPlacement.DeletionMark 
		|   AND DocumentGoodsPickingPlacement.Status IN (&Statuses)"; 
	
	Query.Text = StrReplace(Query.Text, "&PerformerTitle", NStr("vi = '""Người thực hiện""';
																|ru = '""Исполнитель""';
																|en = '""Assignee""'; fa = '""Assignee""';
																|it = '""Assignee""';
																|pl = '""Assignee""';
																|tr = '""İcracı""'"));	
	Return Query;
	
EndFunction

Function GoodsReceiptNoteList() Export

	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsReceiptNote.Ref AS Ref,
	|	GoodsReceiptNote.Number AS Number,
	|	GoodsReceiptNote.Date AS Date,
	|	GoodsReceiptNote.Comment AS Comment,
	|	GoodsReceiptNote.Status AS Status,
	|	GoodsReceiptNote.Premise AS Premise,  
	|	GoodsReceiptNote.Sender AS Sender,
	|	GoodsReceiptNote.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN GoodsReceiptNote.IncomingDocumentNumber = """"
	|			THEN GoodsReceiptNote.Number
	|		ELSE GoodsReceiptNote.IncomingDocumentNumber
	|	END AS IncomingDocumentNumber,
	|	CASE
	|		WHEN GoodsReceiptNote.IncomingDocumentDate = DATETIME(1, 1, 1, 0, 0, 0)
	|			THEN GoodsReceiptNote.Date
	|		ELSE GoodsReceiptNote.IncomingDocumentDate
	|	END AS IncomingDocumentDate,
	|	GoodsReceiptNote.Performer AS Performer,
	|	&PerformerTitle AS PerformerTitle,
	|	GoodsReceiptNote.ReferenceOrder AS ReferenceOrder,
	|	GoodsReceiptNote.ReferenceOrder.Number AS OrderNumber__,
	|	GoodsReceiptNote.ReferenceOrder.Date AS Order_Date,
	|	VALUETYPE(GoodsReceiptNote.ReferenceOrder) AS ReferenceOrderPresentation
	|FROM
	|	Document.GoodsReceiptNote AS GoodsReceiptNote
	|WHERE
	|	GoodsReceiptNote.Warehouse = &Warehouse
	|	AND &ConditionPremises
	|	AND &ConditionExecutor
	|	AND NOT GoodsReceiptNote.DeletionMark
	|	AND GoodsReceiptNote.Posted 
	|   AND GoodsReceiptNote.Status IN (&Statuses)";
	
	Query.Text = StrReplace(Query.Text, "&PerformerTitle", NStr("vi = '""Người thực hiện""';
																|ru = '""Исполнитель""';
																|en = '""Assignee""'; fa = '""Assignee""';
																|it = '""Assignee""';
																|pl = '""Assignee""';
																|tr = '""İcracı""'"));
	Return Query;
	
EndFunction

#EndRegion 

#Region ShippingCounters

// Creates and returns a request for a list of documents Goods Issue.
//		
//	Returns:
//		Query - request for a list of documents Goods issue.
//
Function RequestListOfSpendingOrders() Export
	
	Query = New Query;
		
	Query.Text = 
	"SELECT
	|	GoodsIssueNote.Ref AS Ref,
	|	GoodsIssueNote.Number AS Number,
	|	GoodsIssueNote.Date AS Date,
	|	GoodsIssueNote.Status AS Status,
	|	GoodsIssueNote.Recipient AS Recipient,
	|	GoodsIssueNote.EmployeeResponsible AS EmployeeResponsible,
	|	GoodsIssueNote.Inspector AS Inspector,
	|	&ResponsibleTitle AS ResponsibleTitle
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNote
	|WHERE
	|	GoodsIssueNote.Warehouse = &Warehouse
	|	AND NOT GoodsIssueNote.DeletionMark
	|	AND GoodsIssueNote.Posted";
	
	Return Query;
	
EndFunction

// Creates and returns a request for a list of documents Selection, placement of goods.
//		
//	Returns:
//		Query - request a list of documents Selection, placement of goods.
//
Function RequestListOfSelectionTasks() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DocumentGoodsPickingPlacement.Ref AS Ref,
	|	DocumentGoodsPickingPlacement.DeletionMark AS DeletionMark,
	|	DocumentGoodsPickingPlacement.Number AS Number,
	|	DocumentGoodsPickingPlacement.Date AS Date,
	|	DocumentGoodsPickingPlacement.Posted AS Posted,
	|	DocumentGoodsPickingPlacement.OperationKind AS OperationKind,
	|	DocumentGoodsPickingPlacement.ReceivingArea AS ReceivingArea,
	|	DocumentGoodsPickingPlacement.Performer AS Performer,
	|	DocumentGoodsPickingPlacement.Comment AS Comment,
	|	DocumentGoodsPickingPlacement.Status AS Status,
	|	DocumentGoodsPickingPlacement.VolumePutAway AS VolumePutAway,
	|	DocumentGoodsPickingPlacement.WeightPlacement AS WeightPlacement,
	|	&PerformerTitle AS PerformerTitle
	|FROM
	|	Document.GoodsPickingPlacement AS DocumentGoodsPickingPlacement
	|WHERE
	|	DocumentGoodsPickingPlacement.ShippingZone = &ShippingZone
	|	AND DocumentGoodsPickingPlacement.Warehouse = &Warehouse
	|	AND DocumentGoodsPickingPlacement.Posted
	|	AND NOT DocumentGoodsPickingPlacement.DeletionMark
	|	AND DocumentGoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter) 
	|	AND DocumentGoodsPickingPlacement.Status IN (&Statuses)";
	
	Return Query;
	
EndFunction

#EndRegion 

#Region CountersOtherOperations

Function RecountsList() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	InventoryRecount.Ref AS Ref,
	|	InventoryRecount.Number AS Number,
	|	InventoryRecount.Date AS Date,
	|	InventoryRecount.Performer AS Performer,
	|	InventoryRecount.Comment AS Comment,
	|	InventoryRecount.Warehouse AS Warehouse,
	|	InventoryRecount.Status AS Status,
	|	&PerformerTitle AS PerformerTitle
	|FROM
	|	Document.InventoryRecount AS InventoryRecount
	|WHERE
	|	InventoryRecount.Posted
	|	AND &ConditionExecutor
	|	AND NOT InventoryRecount.DeletionMark
	|	AND InventoryRecount.Warehouse = &Warehouse
	|	AND InventoryRecount.Status = &Status
	|	AND &ConditionPremises";
	
	Query.Text = StrReplace(Query.Text, "&PerformerTitle", NStr("vi = '""Người thực hiện""';
																|ru = '""Исполнитель""';
																|en = '""Assignee""'; fa = '""Assignee""';
																|it = '""Assignee""';
																|pl = '""Assignee""';
																|tr = '""İcracı""'"));	
	Return Query;
	
EndFunction

Function TransferJobList() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DocumentGoodsPickingPlacement.Ref AS Ref,
		|	DocumentGoodsPickingPlacement.DeletionMark AS DeletionMark,
		|	DocumentGoodsPickingPlacement.Number AS Number,
		|	DocumentGoodsPickingPlacement.Date AS Date,
		|	DocumentGoodsPickingPlacement.Posted AS Posted,
		|	DocumentGoodsPickingPlacement.OperationKind AS OperationKind,
		|	DocumentGoodsPickingPlacement.ReceivingArea AS ReceivingArea,
		|	DocumentGoodsPickingPlacement.Performer AS Performer,
		|	DocumentGoodsPickingPlacement.Comment AS Comment,
		|	DocumentGoodsPickingPlacement.Status AS Status,
		|	DocumentGoodsPickingPlacement.VolumePutAway AS VolumePutAway,
		|	DocumentGoodsPickingPlacement.WeightPlacement AS WeightPlacement,
		|	&PerformerTitle AS PerformerTitle
		|FROM
		|	Document.GoodsPickingPlacement AS DocumentGoodsPickingPlacement
		|WHERE
		|	DocumentGoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Move)
		|	AND DocumentGoodsPickingPlacement.Warehouse = &Warehouse
		|	AND &ConditionExecutor
		|	AND &ConditionPremises
		|	AND DocumentGoodsPickingPlacement.Posted
		|	AND NOT DocumentGoodsPickingPlacement.DeletionMark 
		|   AND DocumentGoodsPickingPlacement.Status IN (&Statuses)";
	
	Query.Text = StrReplace(Query.Text, "&PerformerTitle", NStr("vi = '""Người thực hiện""';
																|ru = '""Исполнитель""';
																|en = '""Assignee""'; fa = '""Assignee""';
																|it = '""Assignee""';
																|pl = '""Assignee""';
																|tr = '""İcracı""'"));
	Return Query;
	
EndFunction

Function LockList() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StorageBinsLocks.Cell AS Cell,
		|	StorageBinsLocks.LockType AS LockType,
		|	CASE
		|		WHEN StorageBinsLocks.Recorder REFS Document.SetStorageBinLocks
		|			THEN CAST(StorageBinsLocks.Recorder AS Document.SetStorageBinLocks).EmployeeResponsible
		|		WHEN StorageBinsLocks.Recorder REFS Document.InventoryRecount
		|			THEN CAST(StorageBinsLocks.Recorder AS Document.InventoryRecount).EmployeeResponsible
		|	END AS EmployeeResponsible
		|FROM
		|	InformationRegister.StorageBinsLocks AS StorageBinsLocks
		|WHERE
		|	StorageBinsLocks.Active
		|	AND StorageBinsLocks.Cell.Owner = &Warehouse
		|	AND &ConditionPremises";
	
	Return Query;
	
EndFunction

#EndRegion

#If Not MobileStandaloneServer Then
	
// Creates a new document Goods Issue.
//
//	Parameters:
//		FillingStructure - Structure - See FillingStructureOfExpenseOrder().
//		
//	Returns:
//		Structure - a structure with the following keys:
//		*Ref - DocumentRef.GoodsIssueNote, Undefined- link to the Goods Issue Order.
//		*HasError - Boolean - error flag.
//
Function NewSpendingOrder(FillingStructure) Export
	
	Recipients = New Map;
	ShipmentReferenceOrder = FillingStructure.ShipmentReferences[0];
	
	StructureOfParametersForCreatingSpendingOrders = WarehousesServer.ParametersForReissuingSpendingOrders();
	StructureOfParametersForCreatingSpendingOrders.Warehouse = FillingStructure.Warehouse;
	StructureOfParametersForCreatingSpendingOrders.Premise = FillingStructure.Premise;
	
	StructureOfParametersForCreatingSpendingOrders.ShippingZone = Catalogs.StorageBins.DefaultShippingZone(
		FillingStructure.Warehouse, FillingStructure.Premise);
	
	ReferenceArray = New Array;
	Recipients.Insert(FillingStructure.Recipient, ReferenceArray);
	ReferenceArray.Add(ShipmentReferenceOrder);
	
	If Recipients.Count() > 0 Then
		
		StructureOfParametersForCreatingSpendingOrders.TransportationJob = Undefined;
		
		For Each Recipient In Recipients Do
			StructureOfParametersForCreatingSpendingOrders.Recipient = Recipient.Key;
			StructureOfParametersForCreatingSpendingOrders.ShipmentReferences = Recipient.Value;
			ExecutionStructure = WarehousesServer.ReissueSpendingOrders(StructureOfParametersForCreatingSpendingOrders);
		EndDo;
	Else
		ExecutionStructure = New Structure("HasError", False);
	EndIf;
	
	Ref = LinkToSpendingOrder(ShipmentReferenceOrder);
	ExecutionStructure.Insert("Ref", Ref);
	ExecutionStructure.Insert("BatchIndicationIsRequired", False);
	ExecutionStructure.Delete("ExecutedOrders");
	If Not ValueIsFilled(Ref) Then
		Return ExecutionStructure;
	EndIf;

	DocumentObject = Ref.GetObject();
	If DocumentObject.Status = Enums.GoodsIssueNoteStatuses.Prepared 
		Or DocumentObject.Status = Enums.GoodsIssueNoteStatuses.ForPicking Then
			
		BatchIndicationIsRequired = CheckStatusOfBatchIndicationWhenPlanningSelection(Ref, FillingStructure.Warehouse);
		If BatchIndicationIsRequired Then
			ExecutionStructure.Insert("BatchIndicationIsRequired", True);
		EndIf;
		
		DocumentObject.Status = Enums.GoodsIssueNoteStatuses.ForPicking;
		DocumentObject.Write(DocumentWriteMode.Posting);
	EndIf;
	
	Return ExecutionStructure;
	
EndFunction 

// Returns a link to the Goods Issue for the passed order.
//
//	Parameters:
//		ShipmentReferenceOrder - DefinedType.ShipmentReferenceOrder - Link to the order.
//		
//	Returns:
//		DocumentRef.GoodsIssueNote - link to the Goods Issue Order.
//
Function LinkToSpendingOrder(ShipmentReferenceOrder) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED TOP 1
		|	GoodsByReferences.Ref AS Ref
		|FROM
		|	Document.GoodsIssueNote.GoodsByReferences AS GoodsByReferences
		|WHERE
		|	GoodsByReferences.ReferenceOrder = &ReferenceOrder
		|	AND GoodsByReferences.Ref.Posted
		|
		|ORDER BY
		|	GoodsByReferences.Ref.Ref DESC";
	
	Query.SetParameter("ReferenceOrder", ShipmentReferenceOrder);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Next() Then
		Return SelectionDetailRecords.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Creates a new Task document for selecting goods.
//
//	Parameters:
//		ExpenseOrder - DocumentRef.GoodsIssueNote - link to the spending order
//			for which you want to create a selection.
//		
//	Returns:
//		DocumentRef.GoodsPickingPlacement - link to the created document Selection, placement of goods.
//
Function NewSelectionOfGoods(ExpenseOrder) Export
	
	FilterObject = Documents.GoodsPickingPlacement.CreateDocument();
	FilterObject.Fill(ExpenseOrder);
	FilterObject.Date = CurrentSessionDate();
	FilterObject.Performer = Users.CurrentUser();
	
	ConditionForSelectingRows = New Structure;
	ConditionForSelectingRows.Insert("Cell", Catalogs.StorageBins.EmptyRef());
	FoundRows = FilterObject.GoodsFilter.FindRows(ConditionForSelectingRows);
	For Each DeleteLine In FoundRows Do
		FilterObject.GoodsFilter.Delete(DeleteLine);
	EndDo;
		
	If FilterObject.GoodsFilter.Count() > 0 Then
		Try
			FilterObject.Write(DocumentWriteMode.Posting);
			Return FilterObject.Ref;
		Except
			Return Documents.GoodsPickingPlacement.EmptyRef();
		EndTry;
	Else
		Return Documents.GoodsPickingPlacement.EmptyRef();
	EndIf;
	
EndFunction

// Creates a new Task document for placing goods.
//
//	Parameters:
//		ItemPlacementParameters - Structure - See ParametersForCreatingItemPlacement().
//		
//	Returns:
//		DocumentRef.GoodsPickingPlacement - link to the created document Selection, placement of goods.
//
Function NewPlacementOfItems(ItemPlacementParameters) Export
	
	ReturnStructure = New Structure("Ref, CheckErrorText", Undefined, "");
	
	Manager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = Manager;
	
	Query.Text =
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Series AS Series,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Package AS Package
	|INTO RequestProductTable
	|FROM
	|	&ProductsTable AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsInStorageBinsBalance.Products AS Products,
	|	GoodsInStorageBinsBalance.Characteristic AS Characteristic,
	|	GoodsInStorageBinsBalance.Purpose AS Purpose,
	|	GoodsInStorageBinsBalance.Series,
	|	GoodsInStorageBinsBalance.Package AS Package,
	|	CASE
	|		WHEN GoodsInStorageBinsBalance.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
	|			THEN CAST(GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance - 0.5 AS NUMBER(15, 0))
	|		ELSE GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance
	|	END AS NumberOfPackages
	|INTO ItemsInItemBalanceBoxes
	|FROM
	|	AccumulationRegister.GoodsInStorageBins.Balance(
	|			,
	|			(&ByAllProducts
	|				OR (Products, Characteristic, Series, Purpose, Package) IN
	|					(SELECT
	|						Table.Products AS Products,
	|						Table.Characteristic AS Characteristic,
	|						Table.Series AS Series,
	|				        Table.Purpose AS Purpose,
	|				        Table.Package AS Package
	|					FROM
	|						RequestProductTable AS Table))
	|				AND Cell = &AcceptanceZones) AS GoodsInStorageBinsBalance
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS PoliciesSeriesAccounting
	|		ON GoodsInStorageBinsBalance.Products.ProductKind = PoliciesSeriesAccounting.Ref
	|			AND (PoliciesSeriesAccounting.Warehouse = &Warehouse)
	|WHERE
	|	GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance > 0
	|; 
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Purpose AS Purpose,
	|	NestedQuery.Series,
	|	NestedQuery.Package AS Package,
	|	MIN(NestedQuery.NumberOfPackages) AS NumberOfPackages
	|INTO ProductsTable
	|FROM
	|	(SELECT
	|		ProductsTable.Products AS Products,
	|		ProductsTable.Characteristic AS Characteristic,
	|		ProductsTable.Purpose AS Purpose,
	|		ProductsTable.Series AS Series,
	| 		ProductsTable.Package AS Package,
	|		ProductsTable.NumberOfPackages AS NumberOfPackages
	|	FROM
	|		RequestProductTable AS  ProductsTable
	|
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsInStorageBinsBalance.Products,
	|		GoodsInStorageBinsBalance.Characteristic,
	|		GoodsInStorageBinsBalance.Purpose,
	|		GoodsInStorageBinsBalance.Series,
	|		GoodsInStorageBinsBalance.Package,
	|		GoodsInStorageBinsBalance.NumberOfPackages 
	|	FROM
	|		ItemsInItemBalanceBoxes AS  GoodsInStorageBinsBalance) AS NestedQuery 
	|
	|GROUP BY 
	|	NestedQuery.Series,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Package,
	|	NestedQuery.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RequestProductTable";

	Query.SetParameter("AcceptanceZones", ItemPlacementParameters.ReceivingArea);
	Query.SetParameter("Warehouse", ItemPlacementParameters.Warehouse);
	Query.SetParameter("ProductsTable", ItemPlacementParameters.ProductsTable);
	Query.SetParameter("ByAllProducts", ItemPlacementParameters.ByAllProducts);
	
	Results = Query.ExecuteBatch(); 
	
	Selection = Results[2].Select();
	Selection.Next();
	
	If Selection.Count = 0 Then
		MessageText = NStr("vi = 'Không tạo nhiệm vụ sắp xếp: tất cả hàng hóa hoặc là đã được sắp xếp hoặc là đã có nhiệm vụ sắp xếp đối với các hàng hóa đó.';
							|ru = 'Задания на размещение не сформированы: все товары или уже размещены, или по ним уже есть задания на размещение.';
							|en = 'Cannot generate a Put-away task: all items are already in storage bins or in Put-away lists.'; fa = 'Cannot generate a Put-away task: all items are already in storage bins or in Put-away lists.';
							|it = 'I task per collocamento non sono stati generati: tutti i prodotti sono stati già collocati o sono già presenti i task per collocamento.';
							|pl = 'Nie utworzono zadań na rozmieszczenie: wszystkie wiersze pozycji lub już są rozmieszczone, lub według nich już są zadania na rozmieszczenie.';
							|tr = 'Yerleştirme görevleri oluşturulmadı: tüm ürünler ya zaten yerleştirildi ya da bunlar için zaten yerleştirme görevleri mevcut.'");
		ReturnStructure.CheckErrorText = MessageText;
		Return ReturnStructure;
	EndIf;
	
	CheckError = False;
	
	PlacementResult = WarehousesServer.PlaceGoodsInCells(Manager, ItemPlacementParameters.Warehouse, ItemPlacementParameters.Premise,
		Catalogs.WarehouseZones.EmptyRef(), ItemPlacementParameters.ReceivingArea, CheckError, False);
	
	If CheckError Then
		Return ReturnStructure;
	EndIf;
	
	If PlacementResult.ResultsTable.Count() = 0 Then
		MessageText = NStr("vi = 'Không tạo nhiệm vụ sắp xếp: không thể sắp xếp mặt hàng theo quy tắc sắp xếp.';
							|ru = 'Задания на размещение не сформированы: не удалось разместить номенклатуру согласно правилам размещения.';
							|en = 'Cannot generate a Put-away task according to the put-away rules.'; fa = 'Cannot generate a Put-away task according to the put-away rules.';
							|it = 'I task per collocamento non sono stati generati: impossibile collocare l''articolo in base alle regole di collocamento.';
							|pl = 'Nie utworzono zadań na rozmieszczenie: nie udało się rozmieścić produkty zgodnie z regułami rozmieszczenia.';
							|tr = 'Yerleştirme görevleri oluşturulmadı: ürün gamı, yerleştirme kurallarına göre yerleştirilemedi.'");
		ReturnStructure.CheckErrorText = MessageText;
		Return ReturnStructure;
	EndIf;
	
	TableOfWorkPlots = New ValueTable;
	TableOfWorkPlots.Columns.Add("WarehouseZone", New TypeDescription("CatalogRef.WarehouseZones"));
	NewRow = TableOfWorkPlots.Add();
	NewRow.WarehouseZone = Catalogs.WarehouseZones.EmptyRef();
	
	ImpossibleSet = 9999999999;

	MaximumVolume_ = ?(ItemPlacementParameters.LimitByVolume, ItemPlacementParameters.LimitationByVolume, ImpossibleSet);
	MaximumWeight = ?(ItemPlacementParameters.LimitByWeight, ItemPlacementParameters.LimitationByWeight, ImpossibleSet);

	ResultTable2 = SplitLinesByConstraints(PlacementResult.ResultsTable, MaximumVolume_,
		MaximumWeight);

	For Each WorkingSectionLine In TableOfWorkPlots Do
		
		// Splitting by weight and volume. Agreements:
		//	- one person goes to one cell (i.e. the line of the placement result is not split)
		//  - if the weight (volume) of one line is greater than the limits - a separate document is created,
		//		the weight (volume) of which will be greater than the maximum
		//	- splitting by weight (volume) is not optimal, because it is more important to preserve the order of traversal
		//			(it is better to have more tasks, but each one can be bypassed faster).
		
		DocumentScope    = 0;
		DocumentWeight	  = 0;
		
		CurrentDocument =  Documents.GoodsPickingPlacement.CreateDocument();
		CurrentDocument.Date 				= CurrentSessionDate();
		CurrentDocument.Status 				= Enums.StatusesOfGoodsPickingPlacement.Prepared2;
		CurrentDocument.OperationKind 		= Enums.OperationKindsOfGoodsPlacementPicking.Location;
		CurrentDocument.Warehouse 				= ItemPlacementParameters.Warehouse;
		CurrentDocument.Premise 			= ItemPlacementParameters.Premise;
		CurrentDocument.ReceivingArea		 	= ItemPlacementParameters.ReceivingArea;
		CurrentDocument.EmployeeResponsible 		= Users.CurrentUser();		
		CurrentDocument.WarehouseZone 		= WorkingSectionLine.WarehouseZone;		
		CurrentDocument.Performer         = ItemPlacementParameters.Performer;
		
		PopulationTable = ResultTable2.CopyColumns();
		
		QuantityProcessed = 0;
		
		For Each RowOfTables In ResultTable2 Do

			If (DocumentScope + RowOfTables.PackageVolume * RowOfTables.NumberOfPackages) > MaximumVolume_
				Or (DocumentWeight + RowOfTables.PackageWeight * RowOfTables.NumberOfPackages) > MaximumWeight Then

				WarehousesServer.AddMultiTurnContainerToPlacementTable(PopulationTable);
				CommonClientServer.SupplementTable(PopulationTable, CurrentDocument.GoodsPlacement);
				
				WriteDocument(CurrentDocument, DocumentScope, DocumentWeight, ReturnStructure.CheckError); 			
				
				DocumentScope    = 0;
				DocumentWeight	  = 0; 
				
				CurrentDocument = Documents.GoodsPickingPlacement.CreateDocument();
				CurrentDocument.Date 				= CurrentSessionDate();
				CurrentDocument.Status 				= Enums.StatusesOfGoodsPickingPlacement.Prepared2;
				CurrentDocument.OperationKind 		= Enums.OperationKindsOfGoodsPlacementPicking.Location;
				CurrentDocument.Warehouse 				= ItemPlacementParameters.Warehouse;
				CurrentDocument.Premise 			= ItemPlacementParameters.Premise;
				CurrentDocument.ReceivingArea		 	= ItemPlacementParameters.ReceivingArea;
				CurrentDocument.EmployeeResponsible 		= Users.CurrentUser();		
				CurrentDocument.WarehouseZone 		= WorkingSectionLine.WarehouseZone;		
				CurrentDocument.Performer         = ItemPlacementParameters.Performer;

				PopulationTable.Clear();

			EndIf;

			NewRow = PopulationTable.Add();
			FillPropertyValues(NewRow, RowOfTables);

			DocumentScope    = DocumentScope + RowOfTables.PackageVolume * RowOfTables.NumberOfPackages;
			DocumentWeight	  = DocumentWeight + RowOfTables.PackageWeight * RowOfTables.NumberOfPackages;
			QuantityProcessed = QuantityProcessed + 1;

		EndDo;
		
		If PopulationTable.Count() > 0 Then
			
			WarehousesServer.AddMultiTurnContainerToPlacementTable(PopulationTable);
			CommonClientServer.SupplementTable(PopulationTable, CurrentDocument.GoodsPlacement);
			
			CheckError = "";
			WriteDocument(CurrentDocument, DocumentScope, DocumentWeight, CheckError);
			
			ErrorTemplate = ?(ValueIsFilled(ReturnStructure.CheckErrorText), NStr("vi = '
				|%1';
				|ru = '
				|%1';
				|en = '
				|%1'; fa = '
				|%1';
				|it = '
				|%1';
				|pl = '
				|%1';
				|tr = '
				|%1'"),  NStr("vi = '%1';
								|ru = '%1';
								|en = '%1'; fa = '%1';
								|it = '%1';
								|pl = '%1';
								|tr = '%1'")); 
			
			ReturnStructure.CheckErrorText = ReturnStructure.CheckErrorText + StrTemplate(ErrorTemplate, 
				CheckError);
			
		EndIf;
		
	EndDo;
	
	ReturnStructure.Ref = CurrentDocument.Ref;
	
	Return ReturnStructure;
		
EndFunction

#EndIf

// Sets the transferred Status of the spending order.
//
//	Parameters:
//		Ref - DocumentRef.GoodsIssueNote - link to the spending order.
//		Status - EnumRef.GoodsIssueNoteStatuses - The Status of the spending order that needs to be set.
//		Block - Boolean - indicates whether the spending order needs to be blocked before recording. True by default.
//		
//	Returns:
//		Boolean - True if the Status of the spending order has been successfully set.
//
Function SetStatusOfOrder(Ref, Status, Block = True) Export
	
	BlockErrorTemplate = NStr("vi = 'Không thể phong tỏa %1. %2';
								|ru = 'Не удалось заблокировать %1. %2';
								|en = 'Cannot block %1. %2'; fa = 'Cannot block %1. %2';
								|it = 'Impossibile bloccare %1. %2';
								|pl = 'Nie udało się zablokować %1. %2';
								|tr = '%1 engellenemedi. %2'");
	WriteErrorTemplate      = NStr("vi = 'Không thể ghi lại %1. %2';
									|ru = 'Не удалось записать %1. %2';
									|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
									|it = 'Impossibile registrare %1. %2';
									|pl = 'Nie udało się zapisać %1. %2';
									|tr = '%1 kaydedilemedi. %2'");

	If Block Then
		// Capturing an object for editing
		Try
			LockDataForEdit(Ref);
		Except
			ErrorText = StrTemplate(BlockErrorTemplate, Ref,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
				
			Common.MessageToUser(ErrorText, Ref);
			Return False;
		EndTry;
	EndIf;
	
	BeginTransaction();
	Try
	
		DocumentObject = Ref.GetObject();
		
		DocumentObject.Status = Status;
#If Not MobileStandaloneServer Then
		User = Users.CurrentUser();
#Else
		User = MobileWarehouseKeeperWorkspace.CurrentUser();
#EndIf

		If Status = Enums.GoodsIssueNoteStatuses.ForPicking Then 
			DocumentObject.EmployeeResponsible = User;
		ElsIf Status = Enums.GoodsIssueNoteStatuses.DuringChecking Then
			DocumentObject.Inspector = User; 
		ElsIf Status = Enums.GoodsIssueNoteStatuses.ToShip 
			Or Status = Enums.GoodsIssueNoteStatuses.Shipped_ Then
			DocumentObject.ShippedBy = User;
		ElsIf Status = Enums.GoodsIssueNoteStatuses.ForChecking Then
			DocumentObject.Inspector = Undefined;
		ElsIf Status = Enums.GoodsIssueNoteStatuses.Verified Then
			DocumentObject.ShippedBy = Undefined;
		EndIf;
		
#If Not MobileStandaloneServer Then
		RecordingWithConducting = True;
#Else	
		RecordingWithConducting = False;
#EndIf

		If RecordingWithConducting Then
			DocumentObject.Write(DocumentWriteMode.Posting);
		Else
			DocumentObject.Write(DocumentWriteMode.Write);
		EndIf;

		CommitTransaction();
	Except 
		RollbackTransaction();
		
		ErrorText = StrTemplate(WriteErrorTemplate, Ref, 
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
		Common.MessageToUser(ErrorText, Ref);
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// Checks whether the current user has the right to check the spending order
//
//	Returns:
//		Boolean - True if the current user has the right to check their spending order.
//
Function HaveRightToCheckYourOrders() Export
	
#If Not MobileStandaloneServer Then
	Return Users.RolesAvailable("CheckOnlyYourNotes", Users.CurrentUser());
#Else
	Return IsInRole("CheckOnlyYourNotes");
#EndIf

EndFunction

// Checks whether the current user has the right to check the spending order
//
//	Returns:
//		Boolean - True if the current user has the right to check someone else's spending order.
//
Function ThereIsRightToCheckOtherPeopleSOrders() Export
	
#If Not MobileStandaloneServer Then
	Return Users.RolesAvailable("CheckOnlyOtherNotes", Users.CurrentUser());
#Else
	Return IsInRole("CheckOnlyOtherNotes");
#EndIf
	
EndFunction

// Checks and returns whether it is necessary to specify the series when planning the selection.
//
//	Parameters:
//		ExpenseOrder - DocumentRef.GoodsIssueNote - link to the spending order.
//		Warehouse - CatalogRef.Warehouses - link to the warehouse specified in the spending order.
//		
//	Returns:
//		Boolean - True if you need to specify the series when planning the selection.
//
Function CheckStatusOfBatchIndicationWhenPlanningSelection(ExpenseOrder, Warehouse) Export
	
#If Not MobileStandaloneServer Then
	Premise = Common.ObjectAttributeValue(ExpenseOrder, "Premise");
#Else
	Premise = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(ExpenseOrder, "Premise");
#EndIf
	
	ParametersStructure = New Structure("Warehouse, Premise", Warehouse, Premise);
	UseBinLocationWarehousing = GetFunctionalOption("UseBinLocationWarehousing", ParametersStructure);
	
	If Not UseBinLocationWarehousing Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SpendingOrderForGoodsShippedGoods.Products AS Products
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS SpendingOrderForGoodsShippedGoods
		|WHERE
		|	SpendingOrderForGoodsShippedGoods.BatchesIndicationStatus IN(&Statuses)
		|	AND SpendingOrderForGoodsShippedGoods.Ref = &Ref";
	
	Statuses = New Array;
	Statuses.Add(27);
	Statuses.Add(7);
	Statuses.Add(5);

	Query.SetParameter("Statuses", Statuses);
	Query.SetParameter("Ref", ExpenseOrder);
	
	QueryResult = Query.Execute().Select();   
	
	If QueryResult.Next() Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Searches for an object (document, cell, or item) by barcode and returns data about the object.
//
//	Parameters:
//		Barcode - String - the scanned barcode.
//		Warehouse - CatalogRef.Warehouses - link to the warehouse specified in the selections. May be empty.
//		Premise - CatalogRef.Warerooms - link to the premises specified in the selections. May be empty.
//		
//	Returns:
//		Structure - The data structure of the found object:
//			* ObjectKind - String, Undefined - text description of the found object: Item, Cell, or Document.
//			* ErrorText - String - error text when searching for a document.
//			* Goods - Array of Structure: See ItemDataBySchool().
//			* CellData - Structure: See CellDataByWK().
//			* DocumentData - Structure: See DataOfDocumentOnSHK().
//
Function DataOnGeneralBarcode(Barcode, Warehouse, Premise) Export
		
	ObjectData = New Structure();
	ObjectData.Insert("ObjectKind", Undefined);
	ObjectData.Insert("ErrorText", "");
	ObjectData.Insert("Goods", New Array);
	ObjectData.Insert("CellData", New Structure);
	ObjectData.Insert("DocumentData", New Structure);
	
	ItemsBySchool = ItemDataBySchool(Barcode);
	
	If ValueIsFilled(ItemsBySchool) Then 
		ObjectData.ObjectKind = "Products";
		ObjectData.Goods = ItemsBySchool;
		Return ObjectData;
	EndIf;
	
	CellData = CellDataByWK(Warehouse, Premise, Barcode);
	
	If ValueIsFilled(CellData.Cell) Then
		ObjectData.ObjectKind = "Cell";
		ObjectData.CellData = CellData;
		Return ObjectData;
	EndIf;
		
	DocumentData = DataOfDocumentOnSHK(Barcode, Warehouse);
	
	If ValueIsFilled(DocumentData.References) Then
		ObjectData.ObjectKind = "Document"; 
		ObjectData.DocumentData = DocumentData;
		Return ObjectData;
	EndIf;
		
	ObjectData.ErrorText = NStr("vi = 'Mã vạch của ô, hàng hóa hoặc chứng từ không được nhận dạng.
		|Có thể kho đã chỉ định không chính xác.';
		|ru = 'Штрихкод ячейки, товара или документа не распознан.
		|Возможно неверно указан склад.';
		|en = 'The barcode of the storage bin, item, or document is not recognized.
		|The warehouse may be specified incorrectly.'; fa = 'The barcode of the storage bin, item, or document is not recognized.
		|The warehouse may be specified incorrectly.';
		|it = 'The barcode of the storage bin, item, or document is not recognized.
		|The warehouse may be specified incorrectly.';
		|pl = 'The barcode of the storage bin, item, or document is not recognized.
		|The warehouse may be specified incorrectly.';
		|tr = 'Depo yeri, ürün veya belge barkodu tanınmadı. 
		|Ambar yanlış belirtilmiş olabilir'");
	
	Return ObjectData;
	
EndFunction

// Searches for a document (order or warehouse) by barcode and returns data about the document.
//
//	Parameters:
//		Barcode - String - the scanned barcode.
//		Warehouse - CatalogRef.Warehouses - link to the warehouse specified in the selections. May be empty.
//		ContextOfOrder - String - a string description of the order search context.
//		
//	Returns:
//		Structure - structure with properties:
//			* ThisIsOrder_ - Boolean - a sign that the found document is an order.
//			* References - Array of Structure - array of links to the found document(s).
//			* ReferenceOrder - Undefined - link to the order if orders are found.
//			* Direction - String - a string description of the direction of the found document.
//			* Mode - String - a string description of the document search mode.
//			* Barcode - String - The barcode of the scanned document.
//			* ErrorText - String - the text of the document search error.
//
Function DataOfDocumentOnSHK(Barcode, Warehouse, ContextOfOrder = "") Export
	
	SearchResult = DocumentSearchResultBySchool();
	SearchResult.Mode = "DocumentSearch";
	SearchResult.Barcode = Barcode;
	
	DocumentsArray = New Array;
	DocumentsArray.Add(Type("DocumentRef.GoodsIssueNote"));
	DocumentsArray.Add(Type("DocumentRef.GoodsReceiptNote"));
	DocumentsArray.Add(Type("DocumentRef.GoodsPickingPlacement"));
    DocumentsArray.Add(Type("DocumentRef.InventoryRecount")); 
		
	BlankRefsArray = New Array;
	BlankRefsArray.Add(Documents.GoodsIssueNote.EmptyRef());
	BlankRefsArray.Add(Documents.GoodsReceiptNote.EmptyRef());
	BlankRefsArray.Add(Documents.GoodsPickingPlacement.EmptyRef());
	BlankRefsArray.Add(Documents.InventoryRecount.EmptyRef()); 
	
	ArrayOfShipmentTypes = Metadata.DefinedTypes.ShipmentReferenceOrder.Type.Types();
	For Each Type In ArrayOfShipmentTypes Do		
		DocumentName = Metadata.FindByType(Type).FullName();
		EmptyRef = PredefinedValue(DocumentName + ".EmptyRef");
		BlankRefsArray.Add(EmptyRef);		
	EndDo; 
	
	ArrayOfAcceptanceTypes = Metadata.DefinedTypes.ReceiptReferenceOrder.Type.Types();
	For Each Type In ArrayOfAcceptanceTypes Do		
		DocumentName = Metadata.FindByType(Type).FullName();
		EmptyRef = PredefinedValue(DocumentName + ".EmptyRef");
		BlankRefsArray.Add(EmptyRef);		
	EndDo;
	
#If Not MobileStandaloneServer Then	
	References = BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Barcode, BlankRefsArray); 
#Else	
	References = MobileWarehouseKeeperWorkspace.GetLinkFromBarcodeOfTabularDocument(Barcode, BlankRefsArray); 
#EndIf
	
	// The barcode document was not found in Infobase
	If Not ValueIsFilled(References) Then
		Return SearchResult;
	EndIf;	
	
	DocumentReference = References[0]; 
				
	ThisIsOrder_ = DocumentsArray.Find(TypeOf(DocumentReference)) = Undefined;

	// General search, without the context of the order
	If Not ValueIsFilled(ContextOfOrder) And Not ThisIsOrder_ Then 
				
		If TypeOf(DocumentReference) = Type("DocumentRef.GoodsPickingPlacement") Then	
#If Not MobileStandaloneServer Then	
			OperationKind = Common.ObjectAttributeValue(DocumentReference, "OperationKind"); 
#Else	
			OperationKind = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(DocumentReference, "OperationKind");
#EndIf
			If OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter Then
				SearchResult.Direction = "Shipment";
			ElsIf OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
				SearchResult.Direction = "Receiving";
			Else
				SearchResult.Direction = "Move";
			EndIf;
		Else
			CheckStatusOfRecalculationOfItems(DocumentReference, SearchResult);
		EndIf;
		
		// Document of warehouse of operation found
		SearchResult.ThisIsOrder_ = ThisIsOrder_;
		SearchResult.References.Add(DocumentReference);
		Return SearchResult;
		
	ElsIf ValueIsFilled(ContextOfOrder) And Not ThisIsOrder_ Then 
		// The content search of the order, and the document of the warehouse of operation was found
		Return SearchResult;
	ElsIf ValueIsFilled(ContextOfOrder) Then
		SearchResult.Mode = "DocumentSelection";
	EndIf;
		
	ThisIsShipment = ArrayOfShipmentTypes.Find(TypeOf(DocumentReference)) <> Undefined;
	ThisIsAcceptance = ArrayOfAcceptanceTypes.Find(TypeOf(DocumentReference)) <> Undefined;
	
	// A content search for an order, but an order was found not by context and not a two-sided document
	If Not (ThisIsShipment And ThisIsAcceptance)
		And ((ThisIsShipment And ContextOfOrder = "Receiving")
		Or (ThisIsAcceptance And ContextOfOrder = "Shipment")) Then
		 Return SearchResult;
	EndIf;
	 
	// A document was found that was not a warehouse of operation and not an order
	If Not ThisIsShipment And Not ThisIsAcceptance Then
		Return SearchResult;
	EndIf;
		
	If Not ValueIsFilled(ContextOfOrder) And Not (ThisIsShipment And ThisIsAcceptance) Then
		
		OrdersByReferences = OrdersByReferences(DocumentReference, Catalogs.Warehouses.EmptyRef(), ThisIsShipment, 
			ThisIsAcceptance);
		If OrdersByReferences.LinksToOrders.Count() Then  
			
			SearchResult.Direction = OrdersByReferences.DirectionOfOrders;
			SearchResult.ReferenceOrder = DocumentReference;
			SearchResult.ThisIsOrder_ = False;
			SearchResult.References = OrdersByReferences.LinksToOrders;
			Return SearchResult;
		EndIf;
		
	EndIf;
	
#If Not MobileStandaloneServer Then	
	// General search, without the context of the order or the context of the acceptance search - checking the settings of the purchase Contract
	If Not ValueIsFilled(ContextOfOrder) Or ContextOfOrder = "Receiving" Then
		
		ArrayForPurchaseContract = New Array;
		ArrayForPurchaseContract.Add(Type("DocumentRef.PurchaseOrder"));
		ArrayForPurchaseContract.Add(Type("DocumentRef.GoodsReceiptForStorage"));
		ArrayForPurchaseContract.Add(Type("DocumentRef.VendorInvoice"));
		
		IndexOf = ArrayForPurchaseContract.Find(TypeOf(DocumentReference));
		If IndexOf <> Undefined Then 
			Contract = Common.ObjectAttributeValue(DocumentReference, "Contract");
			If ValueIsFilled(Contract) Then
				GoodsReceipt = Common.ObjectAttributeValue(Contract, "GoodsReceiptOption"); 
				If ValueIsFilled(GoodsReceipt) 
					And (GoodsReceipt = Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices 
					Or GoodsReceipt = Enums.GoodsReceiptOptions.ByContractsAfterInvoices) Then
					
					// Search for a Contract among orders
					RequestForOrder = RequestForOrderForAcceptance(Warehouse, CurrentSessionDate(), "All", False);
					RequestForOrder.Text = StrReplace(RequestForOrder.Text, "WHERE &ConditionForOrders", 
						"WHERE
						|	GoodsToBeReceivedBalancesAsOfDate.DocumentInflow IN (&ReferencesOfOrders)");	
					RequestForOrder.SetParameter("ReferencesOfOrders", Contract); 
						
					TableOfOrders = RequestForOrder.Execute().Unload();
					If TableOfOrders.Count() Then
						SearchResult.References = Common.ValueTableToArray(TableOfOrders);
						SearchResult.Direction = "Receiving";
					EndIf;
					
					Return SearchResult; 
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// To search for an order and orders for it, you need to specify a warehouse
	If Not ValueIsFilled(Warehouse) Then
		Return SearchResult;
	EndIf;
	
	ShippingDocuments = New Array;
	AcceptanceDocuments = New Array;
	
	If ThisIsShipment Then
		ShippingDocuments.Add(DocumentReference);
	EndIf;
	
	 If ThisIsAcceptance Then
		AcceptanceDocuments.Add(DocumentReference);
	EndIf;
	
	// No orders were found, the order is not a Contract, if it is an order document, search for invoices
	ArrayOfOrderDocuments = ArrayOfOrderDocuments();
	
	IndexOf = ArrayOfOrderDocuments.Find(TypeOf(DocumentReference));
	ThisIsOrderDocument = IndexOf <> Undefined;
	If ThisIsOrderDocument Then
		
		SubordinateDocuments = SubordinateDocuments(DocumentReference, ArrayOfShipmentTypes, ArrayOfAcceptanceTypes,
			ThisIsShipment, ThisIsAcceptance);
			
		CommonClientServer.SupplementArray(ShippingDocuments, SubordinateDocuments.ShippingDocuments);
		CommonClientServer.SupplementArray(AcceptanceDocuments, SubordinateDocuments.AcceptanceDocuments);
	Else
		// The document is not an order. Definition of parent documents 
		// that can be orders-orders/grounds
		ParentalDocuments = ParentalDocuments(DocumentReference, ArrayOfShipmentTypes, ArrayOfAcceptanceTypes,
			ThisIsShipment, ThisIsAcceptance);
		
		CommonClientServer.SupplementArray(ShippingDocuments, ParentalDocuments.ShippingDocuments);
		CommonClientServer.SupplementArray(AcceptanceDocuments, ParentalDocuments.AcceptanceDocuments);
	EndIf;
		
	ReferenceArray = New Array;
	
	DateOfShipmentAcceptance = CurrentSessionDate();
	
	// Determination of the shipment order/orders
	If ThisIsShipment And (Not ValueIsFilled(ContextOfOrder) Or ContextOfOrder = "Shipment") Then 
		
		RequestForOrder = RequestOrderForShipment(Warehouse);
		
		RequestForOrder.SetParameter("Warehouse", 	Warehouse);
		RequestForOrder.SetParameter("DateOfShipment", DateOfShipmentAcceptance);
		IssueInvoicesFirst = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() 
			= Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
		RequestForOrder.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
		RequestForOrder.SetParameter("ShowDetailsShipment", False);
		
		States1 = New Array; 
		For Each Value In Enums.GoodsPickingStates Do 
			States1.Add(Value);
		EndDo;
		RequestForOrder.SetParameter("States1", States1);
		
		RequestForOrder.Text = StrReplace(RequestForOrder.Text, "&ConditionForOrders", "AND ReferencesToShip.DocumentShipments IN (&ReferencesOfOrders)");	
		RequestForOrder.SetParameter("ReferencesOfOrders", ShippingDocuments);
		
		TableOfOrders = RequestForOrder.Execute().Unload(); 
		If TableOfOrders.Count() Then
			ReferenceArray = Common.ValueTableToArray(TableOfOrders);
			ThisIsShipment = True;
			ThisIsAcceptance = False;
		EndIf;
	EndIf;
	
	// Determination of the order/acceptance orders
	If ThisIsAcceptance And (Not ValueIsFilled(ContextOfOrder) Or ContextOfOrder = "Receiving") Then
		
		RequestForOrder = RequestForOrderForAcceptance(Warehouse, DateOfShipmentAcceptance, "All", False);
		
		RequestForOrder.Text = StrReplace(RequestForOrder.Text, "WHERE &ConditionForOrders", 
			"WHERE
			|	GoodsToBeReceivedBalancesAsOfDate.DocumentInflow IN (&ReferencesOfOrders)");	
		RequestForOrder.SetParameter("ReferencesOfOrders", AcceptanceDocuments); 
		
		TableOfOrders = RequestForOrder.Execute().Unload();
		
		If TableOfOrders.Count() Then
			ReferenceArray = Common.ValueTableToArray(TableOfOrders);
			ThisIsShipment = False;
			ThisIsAcceptance = True;
		EndIf;	
	EndIf;
			
	ReferenceOrder = DocumentReference;
	
	// Final determination of the direction
	If ThisIsShipment And ThisIsAcceptance Then
		SearchResult.Direction = "TwoSided";
	ElsIf ThisIsShipment Then
		SearchResult.Direction = "Shipment";
	ElsIf ThisIsAcceptance Then
		SearchResult.Direction = "Receiving";
	EndIf;

	If ReferenceArray.Count() = 1 Then
		// One order was found, we can search for orders
		ReferenceOrder = ReferenceArray[0].ReferenceOrder;
	ElsIf ReferenceArray.Count() > 1 Then 
		// Several orders were found
		SearchResult.References = ReferenceArray;
		Return SearchResult;
	EndIf;
	
	// General search, without order context - search for orders
	If Not ValueIsFilled(ContextOfOrder) Then  
		// The order can be with two directions of orders
		OrdersByReferences = OrdersByReferences(ReferenceOrder, Warehouse, ThisIsShipment, ThisIsAcceptance);
		If OrdersByReferences.LinksToOrders.Count() Then  
			
			SearchResult.Direction = OrdersByReferences.DirectionOfOrders;
			SearchResult.ReferenceOrder = ReferenceOrder;
			SearchResult.ThisIsOrder_ = False;
			SearchResult.References = OrdersByReferences.LinksToOrders;
			Return SearchResult;
		EndIf;
	EndIf;
	
	// Nothing was found
	SearchResult.References = ReferenceArray; 

#Else 
	
	OrdersByReferences = OrdersByReferences(DocumentReference, Warehouse, ThisIsShipment, ThisIsAcceptance);
	If OrdersByReferences.LinksToOrders.Count() Then  
			
		SearchResult.Direction = OrdersByReferences.DirectionOfOrders;
		SearchResult.ReferenceOrder = DocumentReference;
		SearchResult.ThisIsOrder_ = False;
		SearchResult.References = OrdersByReferences.LinksToOrders;
		Return SearchResult;
	EndIf;
	
#EndIf
	Return SearchResult;
		
EndFunction  

// Searches for a warehouse document (order, selection, recalculation, etc.) by barcode and returns data about the document.
//
//	Parameters:
//		Barcode - String - the scanned barcode.
//		DocumentKind - String - string notation of the document to search for.
//		
//	Returns:
//		Structure - structure with properties:
//			* ThisIsOrder_ - Boolean - a sign that the found document is an order.
//			* References - Array of DocumentRef - array of links to the found document(s).
//			* ReferenceOrder - Undefined - link to the order if orders are found.
//			* Direction - String - a string description of the direction of the found document.
//			* Mode - String - a string description of the document search mode.
//			* Barcode - String - The barcode of the scanned document.
//			* ErrorText - String - the text of the document search error.
//
Function DataOfWarehouseDocumentForSHK(Barcode, DocumentKind) Export
	
	SearchResult = DocumentSearchResultBySchool();
	SearchResult.ThisIsOrder_ = False;
	SearchResult.Barcode = Barcode;

	DocumentsArray = New Array;
	DocumentsArray.Add(Type("DocumentRef.GoodsIssueNote"));
	DocumentsArray.Add(Type("DocumentRef.GoodsReceiptNote"));
	DocumentsArray.Add(Type("DocumentRef.GoodsPickingPlacement"));
	DocumentsArray.Add(Type("DocumentRef.InventoryRecount")); 
		
	BlankRefsArray = New Array;
	BlankRefsArray.Add(Documents.GoodsIssueNote.EmptyRef());
	BlankRefsArray.Add(Documents.GoodsReceiptNote.EmptyRef());
	BlankRefsArray.Add(Documents.GoodsPickingPlacement.EmptyRef());
	BlankRefsArray.Add(Documents.InventoryRecount.EmptyRef()); 
		
#If Not MobileStandaloneServer Then	
	References = BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Barcode, BlankRefsArray); 
#Else	
	References = MobileWarehouseKeeperWorkspace.GetLinkFromBarcodeOfTabularDocument(Barcode, BlankRefsArray); 
#EndIf
	
	// The barcode document was not found in Infobase
	If Not ValueIsFilled(References) Then
		Return SearchResult;
	EndIf;	
	
	DocumentReference = References[0];
	
	// Contextual search for documents
	If (DocumentKind = "ExpenseOrder" 
		And TypeOf(DocumentReference) = Type("DocumentRef.GoodsIssueNote"))
		Or (DocumentKind = "ReceiptGoodsOrder"  
		And TypeOf(DocumentReference) = Type("DocumentRef.GoodsReceiptNote"))
		Or (DocumentKind = "InventoryRecount"  
		And TypeOf(DocumentReference) = Type("DocumentRef.InventoryRecount")) Then 
		
		CheckStatusOfRecalculationOfItems(DocumentReference, SearchResult);
		
		SearchResult.References = References;
		Return SearchResult;
		
	ElsIf (DocumentKind = "SelectionTask" Or DocumentKind = "PlacementJob"
		Or DocumentKind = "Job_GoodsTransfer")
		And TypeOf(DocumentReference) = Type("DocumentRef.GoodsPickingPlacement") Then
		
#If Not MobileStandaloneServer Then	
		OperationKind = Common.ObjectAttributeValue(DocumentReference, "OperationKind"); 
#Else	
		OperationKind = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(DocumentReference, "OperationKind");
#EndIf
		
		If (DocumentKind = "SelectionTask" 
			And OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter)
			Or (DocumentKind = "PlacementJob" 
			And OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location) 
			Or (DocumentKind = "Job_GoodsTransfer" 
			And OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move) Then
			
			SearchResult.References = References;
			Return SearchResult;
		EndIf;
	EndIf;
		
	Return SearchResult;	
	
EndFunction 

// Searches for selection tasks/goods placements based on order data and returns data about documents.
//
//	Parameters:
//		SearchData_ - Structure - described parameters for document search:
//		* Ref - DocumentRef.GoodsIssueNote, Undefined - link to the spending order if they are looking for a selection.
//		* Direction - String - string description of the document direction.
//		
//	Returns:
//		Structure - structure with properties:
//			* ThisIsOrder_ - Boolean - a sign that the found document is an order.
//			* References - Array of DocumentRef - array of links to the found document(s).
//			* ReferenceOrder - Undefined - link to the order if orders are found.
//			* Direction - String - a string description of the direction of the found document.
//			* Mode - String - a string description of the document search mode.
//			* Barcode - String - The barcode of the scanned document.
//			* ErrorText - String - the text of the document search error.
//
Function OrderTaskData(SearchData_) Export
	
	SearchResult = DocumentSearchResultBySchool();
	SearchResult.ThisIsOrder_ = False;
	SearchResult.Mode = "DocumentSelection";
	SearchResult.Direction = SearchData_.Direction;

	Query = New Query;
	
	If SearchData_.Direction = "Receiving" Then 
		
		Query.Text =
			"SELECT ALLOWED 
			|	GoodsPickingPlacement.Ref AS Ref,
			|	GoodsPickingPlacement.Number AS Number,
			|	GoodsPickingPlacement.Date AS Date,
			|	GoodsPickingPlacement.Status AS Status,
			|	CASE
			|		WHEN GoodsPickingPlacement.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.Prepared2)
			|			THEN 0
			|		WHEN GoodsPickingPlacement.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.InProgress)
			|			THEN 1
			|		ELSE 2
			|	END AS JobStatus,
			|	GoodsPickingPlacement.Performer AS Performer,
			|	STRING(""Performer"") AS PerformerTitle
			|FROM
			|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
			|WHERE
			|	GoodsPickingPlacement.Ref.Posted
			|	AND GoodsPickingPlacement.Warehouse = &Warehouse
			|	AND GoodsPickingPlacement.Premise = &Premise
			|	AND GoodsPickingPlacement.ReceivingArea = &ReceivingArea
			|	AND GoodsPickingPlacement.Date >= &Date
			|	AND GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Location)";
		
		Query.SetParameter("Warehouse", SearchData_.Warehouse);
		Query.SetParameter("Premise", SearchData_.Premise);
		Query.SetParameter("ReceivingArea", SearchData_.ReceivingArea);
		Query.SetParameter("Date", SearchData_.DateFromOrder);

	Else 
		
		Query.Text =
			"SELECT
			|	GoodsPickingPlacement.Ref AS Ref,
			|	GoodsPickingPlacement.Number AS Number,
			|	GoodsPickingPlacement.Date AS Date,
			|	GoodsPickingPlacement.Status AS Status,
			|	CASE
			|		WHEN GoodsPickingPlacement.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.Prepared2)
			|			THEN 0
			|		WHEN GoodsPickingPlacement.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.InProgress)
			|			THEN 1
			|		ELSE 2
			|	END AS JobStatus,
			|	GoodsPickingPlacement.Performer AS Performer,
			|	STRING(""Performer"") AS PerformerTitle
			|FROM
			|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
			|WHERE   
			|	GoodsPickingPlacement.Ref.Posted
			|	AND GoodsPickingPlacement.ReferenceOrder = &Ref";
		
		Query.SetParameter("Ref", SearchData_.Ref);
		
	EndIf;
	
	QueryResult = Query.Execute().Unload();
	
#If Not MobileStandaloneServer Then	
	TasksForSelectingPlacement = Common.ValueTableToArray(QueryResult); 
#Else	
	TasksForSelectingPlacement = MobileWarehouseKeeperWorkspace.ValueTableToArray(QueryResult); 
#EndIf 				

	SearchResult.References = TasksForSelectingPlacement;
	Return SearchResult;
	
EndFunction

// Returns a link to the Expense Account/Receipt order(s) for goods under the transferred order(s).
//
//	Parameters:
//		OrdersForShipmentReceipt - DefinedType.ReceiptReferenceOrder - link to the acceptance order;
//			- DefinedType.ShipmentReferenceOrder - link to the shipment order;
//			- Array of DefinedType.ReceiptReferenceOrder, DefinedType.ShipmentReferenceOrder - array of links to orders.
//		Warehouse - CatalogRef.Warehouses - link to the warehouse specified in the selections. May be empty.
//		ThisIsShipment - Boolean - indicates whether to search for spending orders. Does not exclude the value of True y is an acceptance;
//		ThisIsAcceptance - Boolean - indicates whether incoming orders are being searched. Does not exclude the value True y is a load;
//		
//	Returns:
//		Structure - structure with search results for orders:
//			* LinksToOrders - Array of DocumentRef.GoodsIssueNote, DocumentRef.GoodsReceiptNote 
//				- an array of links to orders by order.
//			* DirectionOfOrders - String - string description of the document direction.
//
Function OrdersByReferences(OrdersForShipmentReceipt, Warehouse, ThisIsShipment = False, ThisIsAcceptance = False) Export
	
	OrdersStructure = New Structure();
	OrdersStructure.Insert("LinksToOrders", New Array);
	OrdersStructure.Insert("DirectionOfOrders", "");
	
	If TypeOf(OrdersForShipmentReceipt) <> Type("Array") Then
		References = MobileWarehouseKeeperWorkspaceClientServer.ValueInArray(OrdersForShipmentReceipt);
	Else
		References = OrdersForShipmentReceipt;
	EndIf;
	
	ThisIsShipmentOrder = False;
	ThisIsAcceptanceWarrant = False;
	
	ArrayOfOrders = New Array;
	
	Query = New Query;
	If ThisIsShipment Then
		Query.Text = 
			"SELECT ALLOWED DISTINCT
			|	GoodsByReferences.Ref AS Ref
			|FROM
			|	Document.GoodsIssueNote.GoodsByReferences AS GoodsByReferences
			|WHERE
			|	GoodsByReferences.ReferenceOrder IN(&ReferenceOrder)
			|	AND GoodsByReferences.Ref.Posted
			|	AND (GoodsByReferences.Ref.Warehouse = &Warehouse
			|		OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))";
			
		Query.SetParameter("ReferenceOrder", References);
		Query.SetParameter("Warehouse", Warehouse);
		
		GoodsIssueNotes =  Query.Execute().Unload();
		
		If GoodsIssueNotes.Count() Then
			ArrayOfOrders = GoodsIssueNotes.UnloadColumn("Ref");
			ThisIsShipmentOrder = True;
		EndIf;
	EndIf;
	
	If ThisIsAcceptance Then
		Query.Text =
			"SELECT ALLOWED
			|	GoodsReceiptNote.Ref AS Ref
			|FROM
			|	Document.GoodsReceiptNote AS GoodsReceiptNote
			|WHERE
			|	GoodsReceiptNote.ReferenceOrder IN(&ReferenceOrder)
			|	AND GoodsReceiptNote.Ref.Posted
			|	AND (GoodsReceiptNote.Warehouse = &Warehouse 
			|		OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))"; 
		
		Query.SetParameter("ReferenceOrder", References);
		Query.SetParameter("Warehouse", Warehouse);

		GoodsReceiptNotes = Query.Execute().Unload(); 
		
		If GoodsReceiptNotes.Count() Then
			ArrayOfIncomingOrders = GoodsReceiptNotes.UnloadColumn("Ref");
			MobileWarehouseKeeperWorkspace.SupplementArray(ArrayOfOrders, ArrayOfIncomingOrders);
			ThisIsAcceptanceWarrant = True;
		EndIf;
	EndIf;
	
	If ThisIsShipmentOrder And ThisIsAcceptanceWarrant  Then
		OrdersStructure.DirectionOfOrders = "TwoSided"; 
	ElsIf ThisIsShipmentOrder Then
		OrdersStructure.DirectionOfOrders = "Shipment";
	ElsIf ThisIsAcceptanceWarrant Then
		OrdersStructure.DirectionOfOrders = "Receiving";
	EndIf; 
	
	OrdersStructure.LinksToOrders = ArrayOfOrders;
	
	Return OrdersStructure;
		
EndFunction
	
// Returns the structure, which is then processed by the document barcode search functions.
//
//	Returns:
//		Structure - structure with properties:
//			* ThisIsOrder_ - Boolean - a sign that the found document is an order.
//			* References - Array of DocumentRef - array of links to the found document(s).
//			* ReferenceOrder - Undefined - link to the order if orders are found.
//			* Direction - String - a string description of the direction of the found document.
//			* Mode - String - a string description of the document search mode.
//			* Barcode - String - The barcode of the scanned document.
//			* ErrorText - String - the text of the document search error.
//
Function DocumentSearchResultBySchool() Export
	
	DocumentStructure = New Structure;
	DocumentStructure.Insert("ThisIsOrder_", True);
	DocumentStructure.Insert("References", New Array);
	DocumentStructure.Insert("ReferenceOrder", Undefined);
	DocumentStructure.Insert("Direction", "");
	DocumentStructure.Insert("Mode", "");
	DocumentStructure.Insert("Barcode", "");
	DocumentStructure.Insert("ErrorText", "");
	
	Return DocumentStructure;

EndFunction

// Returns the structure, which is then processed by the procedures for creating a Task for placing goods.
//
//	Returns:
//		Structure - structure with properties:
//			* Warehouse - CatalogRef.Warehouses - the warehouse of the document being created.
//			* Premise - CatalogRef.Warerooms - the location of the document being created.
//			* Performer - CatalogRef.Users - the user responsible for the Task of placing goods.
//			* ReceivingArea - CatalogRef.StorageBins - The inbound area of the document being created.
//			* ProductsTable - ValueTable
//			* LimitByVolume - Boolean - indicates whether the placement being created is being robbed by volume.
//			* LimitByWeight - Boolean - indicates whether the placement being created is being robbed by weight.
//			* LimitationByVolume - Number - numerical volume limit.
//			* LimitationByWeight - Number - numerical weight limit.
//			* ByAllProducts - Boolean - indicates whether a task has been created for the entire item.
//
Function ParametersForCreatingItemPlacement() Export
	
	PlacementParameters = New Structure;
	PlacementParameters.Insert("Warehouse", Catalogs.Warehouses.EmptyRef());
	PlacementParameters.Insert("Premise", Catalogs.Warerooms.EmptyRef()); 
	PlacementParameters.Insert("Performer", Catalogs.Users.EmptyRef());
	PlacementParameters.Insert("ReceivingArea", Catalogs.StorageBins.EmptyRef());
	PlacementParameters.Insert("ProductsTable", New ValueTable);
	PlacementParameters.Insert("LimitByVolume", False);
	PlacementParameters.Insert("LimitByWeight", False);
	PlacementParameters.Insert("LimitationByVolume", 0);
	PlacementParameters.Insert("LimitationByWeight", 0);
	PlacementParameters.Insert("ByAllProducts", False);
	
	Return PlacementParameters;

EndFunction

Function WarehouseProperties(Warehouse) Export
	
	WarehouseProperties = New Structure;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Warehouses.UseBinLocationWarehousing AS UseBinLocationWarehousing,
		|	Warehouses.UseWarehouseManagemantSystemForGoodsReceipt AS UseWarehouseManagemantSystemForGoodsReceipt,
		|	Warehouses.UseWarerooms AS UseWarerooms,
		|	Warehouses.UseGoodsIssueNoteStatuses AS UseGoodsIssueNoteStatuses,
		|	Warehouses.StartDateOfWareroomUse AS StartDateOfWareroomUse
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref = &Warehouse";
	
	Query.SetParameter("Warehouse", Warehouse);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		WarehouseProperties.Insert("UseBinLocationWarehousing", SelectionDetailRecords.UseBinLocationWarehousing);
		WarehouseProperties.Insert("UseWarehouseManagemantSystemForGoodsReceipt", SelectionDetailRecords.UseWarehouseManagemantSystemForGoodsReceipt);
		WarehouseProperties.Insert("UseWarerooms", SelectionDetailRecords.UseWarerooms);
		WarehouseProperties.Insert("UseGoodsIssueNoteStatuses", SelectionDetailRecords.UseGoodsIssueNoteStatuses); 
		WarehouseProperties.Insert("StartDateOfWareroomUse", SelectionDetailRecords.StartDateOfWareroomUse);
	EndDo;
	
	Return WarehouseProperties;
	
EndFunction

// Returns an array with data about the item found by barcode.
//
//	Parameters:
//		Barcode - String - The barcode of the scanned item.
//		
//	Returns:
//		Array of Structure - array of goods search results:
//			* Products -  CatalogRef.Products -link to the found item;
//			* Characteristic - CatalogRef.ItemsCharacteristics -link to the item description;
//			* Series - CatalogRef.ItemsBatches -reference to the series of the nomenclature;
//			* Count - Number - the default number of items. Always 1.
//			* PackageBarcode - String - barcodes of packaging items;
//			* Package - CatalogRef.PackagesAndUnitsOfMeasure -reference to the packaging of the item;
//
Function ItemDataBySchool(Barcode) Export

	Query = New Query;
	Query.Text = 
	"SELECT
	|	ItemsBarcodes.Products AS Products,
	|	ItemsBarcodes.Characteristic AS Characteristic,
	|	ItemsBarcodes.Series	AS Series,
	|	1 AS Count, 
	|	STRING("""") AS PackageBarcode,
	|	CASE
	|		WHEN ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN ItemsBarcodes.Products.UnitOfMeasure
	|		ELSE ItemsBarcodes.Package
	|	END AS Package
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|WHERE
	|	ItemsBarcodes.Barcode = &Barcode";
	
	Query.SetParameter("Barcode", Barcode);
	
	QueryResult = Query.Execute().Unload(); 
	
	If QueryResult.Count() Then
#If Not MobileStandaloneServer Then
		Return Common.ValueTableToArray(QueryResult); 
#Else
		Return MobileWarehouseKeeperWorkspace.ValueTableToArray(QueryResult); 
#EndIf 	
	EndIf;
	
	If Not GetFunctionalOption("UseItemsBatchWarehouse") Then
#If Not MobileStandaloneServer Then
		Return Common.ValueTableToArray(QueryResult); 
#Else
		Return MobileWarehouseKeeperWorkspace.ValueTableToArray(QueryResult); 
#EndIf 	
	EndIf;
	
#If Not MobileStandaloneServer Then
	SeriesInformation = BarcodingOfItemsServer.SeriesInformationFromBarcode(Barcode, True, True, False);
	
	If SeriesInformation.HasError Then
		Return Common.ValueTableToArray(QueryResult);
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	GoodsBatchMovement.Products AS Products,
	|	GoodsBatchMovement.Characteristic	AS Characteristic,
	|	GoodsBatchMovement.Products.UnitOfMeasure AS Package,
	|	1 AS Count, 
	|	STRING("""") AS PackageBarcode,
	|	GoodsBatchMovement.Series AS Series
	|FROM
	|	AccumulationRegister.GoodsBatchMovement AS GoodsBatchMovement
	|		INNER JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON GoodsBatchMovement.Series = ItemsBatches.Ref
 	|		AND ItemsBatches.Number = &BatchNumber
	|		AND ItemsBatches.ValidUntil_ = &ValidUntil_";

	Query.SetParameter("BatchNumber", SeriesInformation.Number);
	Query.SetParameter("ValidUntil_", SeriesInformation.ValidUntil_);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return Common.ValueTableToArray(QueryResult);
#Else
	Return MobileWarehouseKeeperWorkspace.ValueTableToArray(QueryResult); 
#EndIf 	
	
EndFunction

// Returns an array with data about the item found by barcode.
//
//	Parameters:
//		Barcode - String - The barcode of the scanned series.
//		BatchOwner - CatalogRef.ItemKinds - link to the item type.
//		
//	Returns:
//		Structure - structure with properties:
//			* ValidUntil_ - Date - shelf life of the series.
//			* ProductionDate - Date - production date of the series.
//			* Count - Number - the number of the found series.
//			* Number - Number - serial number in the Catalog.
//			* Series - CatalogRef.ItemsBatches - reference to the series of the nomenclature.
//
Function GetParametersOfSeriesByWK(Barcode, BatchOwner) Export 

#If Not MobileStandaloneServer Then
		SeriesUseSettings = Common.ObjectAttributesValues(BatchOwner, "SpecifyNumberWhenRegisteringBatch, UseShelfLifeOnBatchRegistration");
#Else
		SeriesUseSettings = MobileWarehouseKeeperWorkspace.ObjectAttributesValues(BatchOwner, "SpecifyNumberWhenRegisteringBatch, UseShelfLifeOnBatchRegistration");
#EndIf
	
	SeriesParameters = SeriesParameters();
#If Not MobileStandaloneServer Then
	SeriesInformation = BarcodingOfItemsServer.SeriesInformationFromBarcode(Barcode, 
		SeriesUseSettings.SpecifyNumberWhenRegisteringBatch, SeriesUseSettings.UseShelfLifeOnBatchRegistration);
#Else
	SeriesInformation = MobileWarehouseKeeperWorkspace.SeriesInformationFromBarcode(Barcode, 
		SeriesUseSettings.SpecifyNumberWhenRegisteringBatch, SeriesUseSettings.UseShelfLifeOnBatchRegistration);
#EndIf
		
	If SeriesInformation.HasError Then
		Return SeriesParameters;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ISNULL(ItemsBatches.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	ISNULL(ItemsBatches.ValidUntil_, &ValidUntil_) AS ValidUntil_,
	|	ISNULL(ItemsBatches.ProductionDate, DATETIME(1, 1, 1, 0, 0, 0)) AS ProductionDate
	|FROM
	|	Catalog.ItemsBatches AS ItemsBatches
	|WHERE
	|	ItemsBatches.Number = &BatchNumber
	|	AND ItemsBatches.ValidUntil_ = &ValidUntil_
	|	AND ItemsBatches.ProductKind = &ProductKind";
	
	Query.SetParameter("BatchNumber", SeriesInformation.Number);
	Query.SetParameter("ValidUntil_", SeriesInformation.ValidUntil_);
	Query.SetParameter("ProductKind", BatchOwner);

	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
		
	While SelectionDetailRecords.Next() Do
		FillPropertyValues(SeriesParameters, SelectionDetailRecords);
	EndDo;
	
	Return SeriesParameters;

EndFunction

Function GetProductType(Products) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Products.ProductKind AS ProductKind
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.Ref = &Ref";
	
	Query.SetParameter("Ref", Products);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Return SelectionDetailRecords.ProductKind;
	EndDo;
	
	Return Catalogs.ItemKinds.EmptyRef();
	
EndFunction

Function GetCatalogAttributes(Ref, AttributeName) Export
	
	Return Ref[AttributeName];
	
EndFunction

// Returns a structure with data about the found cell by barcode.
//
//	Parameters:
//		Warehouse - CatalogRef.Warehouses - link to the cell warehouse.
//		Premise - CatalogRef.Warerooms - reference to the location of the cell.
//		Barcode - String - The barcode of the scanned cell.
//
//	Returns:
//		Structure - structure with cell data:
//			* Barcode - String - The barcode of the scanned cell.
//			* Cell - CatalogRef.StorageBins -link to the found cell.
//			* ReturnCode - Number - numeric designation of the search result.
//			* CellType - EnumRef.TypesOfStorageCells -cell type.
//			* CellCode - String - the string code of the cell in the Catalog.
//			* CellBarcode - String - The barcode of the scanned cell.
//
Function CellDataByWK(Warehouse, Premise, Barcode) Export
	
	CellStructure_ = FindCellByCode(Warehouse, Premise, Barcode);
	
	If ValueIsFilled(CellStructure_.Cell) Then
		CellStructure_.Insert("Barcode", Barcode);
		Return CellStructure_;
	EndIf;
	
#If Not MobileStandaloneServer Then
	CellStructure_ = WorkplaceOfWarehouseWorkerApplicationInterface.FindCellByBarcode(Warehouse,
	Premise, Barcode, True);
#Else
	CellStructure_ = MobileWarehouseKeeperWorkspace.FindCellByBarcode(Warehouse,
	Premise, Barcode, True);
#EndIf
	
	If CellStructure_.ReturnCode = 0 Then
		CellStructure_.Insert("Cell", Catalogs.StorageBins.EmptyRef());
	Else
#If Not MobileStandaloneServer Then
		CellWarehouseRoom = Common.ObjectAttributesValues(CellStructure_.Cell, "Owner, Premise");
#Else
		CellWarehouseRoom = MobileWarehouseKeeperWorkspace.ObjectAttributesValues(CellStructure_.Cell, "Owner, Premise");
#EndIf
		If Not (Warehouse = CellWarehouseRoom.Owner And Premise = CellWarehouseRoom.Premise) Then 
			CellStructure_.Insert("Cell", Catalogs.StorageBins.EmptyRef());
		EndIf;
	EndIf;
	
	CellStructure_.Insert("Barcode", Barcode);
	
	Return CellStructure_;
	
EndFunction

Function StampsWereScanned(Products, NumberOfPackages, Package, PackageBarcodes) Export
	
	AccountingFeature = GetCatalogAttributes(Products, "AccountingFeature");
	If ValueIsFilled(AccountingFeature) Then
		
		For Each String In PackageBarcodes Do
			
			
			
		EndDo;
		
		Return True;
		
	Else
		Return True;
	EndIf;
	
EndFunction

// Generates a list of users available for selection.
//
//	Parameters:
//		ExcludedUsers - ValueList - list of users to exclude from the selection list.
//		
//	Returns:
//		Boolean - Array - a list of user selections.
//
Function GetListOfUsers(ExcludedUsers = Undefined) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Users.Ref AS Ref
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	NOT Users.IsInternal";
	
	If ValueIsFilled(ExcludedUsers) Then
		Query.Text = Query.Text + "
		|	AND NOT (Users.Ref IN(&List))";
		Query.SetParameter("List", ExcludedUsers);
	EndIf;
	
	QueryResult = Query.Execute();
	
	Return QueryResult.Unload().UnloadColumn("Ref");

EndFunction

#EndRegion

#Region Private

// Returns a structure describing the series data.
//
//	Returns:
//		Structure - structure with properties:
//			* ValidUntil_ - Date - shelf life of the series.
//			* ProductionDate - Date - production date of the series.
//			* Count - Number - the number of the found series.
//			* Number - Number - serial number in the Catalog.
//			* Series - CatalogRef.ItemsBatches - reference to the series of the nomenclature.
//
Function SeriesParameters()
	
	SeriesParameters = New Structure;
	SeriesParameters.Insert("ValidUntil_", Date("00010101"));
	SeriesParameters.Insert("ProductionDate",Date("00010101"));
	SeriesParameters.Insert("Count", 0);
	SeriesParameters.Insert("Number", 0);
	SeriesParameters.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
	
	Return SeriesParameters;
	
EndFunction

Function FindCellByCode(Warehouse, Premise, Barcode)
	
	CellStructure_ = New Structure;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StorageBins.Ref AS Cell
		|FROM
		|	Catalog.StorageBins AS StorageBins
		|WHERE
		|	StorageBins.Code = &Code
		|	AND StorageBins.Owner = &Warehouse
		|	AND StorageBins.Premise = &Premise";
	
	Query.SetParameter("Code", Barcode);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Warehouse", Warehouse);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		CellStructure_.Insert("Cell", Catalogs.StorageBins.EmptyRef());
		Return CellStructure_;
		
	EndIf;
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		
		CellStructure_.Insert("Cell", SelectionDetailRecords.Cell);
		Return CellStructure_;
		
	EndDo;
	
EndFunction

#If Not MobileStandaloneServer Then
Function SplitLinesByConstraints(PlacementOfGoodsInCells, MaximumVolume_, MaximumWeight)

	ResultTable2 = PlacementOfGoodsInCells.CopyColumns();
	RowsWithRecalculatedQuantity = New Array;

	For Each DescriptionOfPlacement In PlacementOfGoodsInCells Do

		ItRemainsToPlace = DescriptionOfPlacement.NumberOfPackages;

		MaximumQuantityByVolume = MaximumQuantityByRestriction(
			DescriptionOfPlacement.PackageVolume,
			MaximumVolume_,
			ItRemainsToPlace);

		MaximumQuantityByWeight = MaximumQuantityByRestriction(
			DescriptionOfPlacement.PackageWeight,
			MaximumWeight,
			ItRemainsToPlace);

		MaximumNumberOfPlacements = Min(MaximumQuantityByVolume, MaximumQuantityByWeight);
		ToRecalculateQuantity = MaximumNumberOfPlacements < ItRemainsToPlace;
		
		While ItRemainsToPlace <> 0 Do

			AssignmentRow2 = ResultTable2.Add();
			FillPropertyValues(AssignmentRow2, DescriptionOfPlacement);

			If ItRemainsToPlace > MaximumNumberOfPlacements Then
				PlacedNumberOfPackages = MaximumNumberOfPlacements;
			Else
				PlacedNumberOfPackages = ItRemainsToPlace;
			EndIf;

			AssignmentRow2.NumberOfPackages = PlacedNumberOfPackages;

			ItRemainsToPlace = ItRemainsToPlace - PlacedNumberOfPackages;
			
			If ToRecalculateQuantity Then
				RowsWithRecalculatedQuantity.Add(AssignmentRow2);
			EndIf;
			
		EndDo;

	EndDo;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsWithRecalculatedQuantity, StructureOfActions,
		ResultTable2);

	Return ResultTable2;

EndFunction  

Function MaximumQuantityByRestriction(Value, Restriction, DefaultValue)
	
	If Value = 0 Then
		Return DefaultValue;
	EndIf;
	
	Return Int(Restriction / Value);
	
EndFunction

Procedure WriteDocument(DocumentObject, VolumeM3, Weight, CheckError) 
	
	Try
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.GoodsPickingPlacement);
		ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject,SeriesSpecificationParameters.Location);
		DocumentObject.Write(DocumentWriteMode.Posting);
		
	Except
		CheckError = ErrorInfo().Description;
	EndTry; 
	
EndProcedure
#EndIf 

Procedure CheckStatusOfRecalculationOfItems(DocumentReference, DocumentStructure)
	
	If TypeOf(DocumentReference) = Type("DocumentRef.InventoryRecount") Then 
#If Not MobileStandaloneServer Then	
		Status = Common.ObjectAttributeValue(DocumentReference, "Status");
#Else	
		Status = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(DocumentReference, "Status"); 
#EndIf
		If Not Status = Enums.InventoryRecountStatuses.EnteringResults Then
			ErrorText = StrTemplate(NStr("vi = 'Việc tính lại hàng hóa có trạng thái ""%1"". Không thể nhập kết quả.';
										|ru = 'Пересчет товаров имеет статус ""%1"". Внесение результатов невозможно.';
										|en = 'Inventory count sheet has the ""%1"" status. Cannot enter the results.'; fa = 'Inventory count sheet has the ""%1"" status. Cannot enter the results.';
										|it = 'Inventory count sheet has the ""%1"" status. Cannot enter the results.';
										|pl = 'Inventory count sheet has the ""%1"" status. Cannot enter the results.';
										|tr = 'Stok sayımı ""%1"" durumunda. Sonuçların girilmesi mümkün değil.'"),
				Status);
			DocumentStructure.ErrorText = ErrorText;
		EndIf;
	EndIf;

EndProcedure

Function ParentalDocuments(DocumentReference, ArrayOfShipmentTypes, ArrayOfAcceptanceTypes, ThisIsShipment, ThisIsAcceptance)
	
	ShippingDocuments = New Array;
	AcceptanceDocuments = New Array;
	
	TypePresentation = Common.TypePresentationString(TypeOf(DocumentReference));
	AttributesList = MobileWarehouseKeeperWorkspaceCached.LinkedAttributes(TypePresentation);
	
	For Each Attribute In AttributesList.RelatedHeaderAttributes Do
		
		AttributeValue = DocumentReference[Attribute.Name];
		
		AttributeType = TypeOf(AttributeValue);

		If Not ValueIsFilled(AttributeValue) Or AttributeValue = DocumentReference Then
			Continue;
		EndIf;
		
		ThisIsShippingDocument = ArrayOfShipmentTypes.Find(AttributeType) <> Undefined;
		ThisIsAcceptanceDocument = ArrayOfAcceptanceTypes.Find(AttributeType) <> Undefined;

		If (ThisIsShipment And ThisIsShippingDocument) 
			And ShippingDocuments.Find(AttributeValue) = Undefined Then
			ShippingDocuments.Add(AttributeValue);
		EndIf;
		
		If (ThisIsAcceptance And ThisIsAcceptanceDocument)
			And AcceptanceDocuments.Find(AttributeValue) = Undefined Then
			AcceptanceDocuments.Add(AttributeValue);
		EndIf;
	EndDo; 
	
	ObjectMetadata = DocumentReference.Metadata(); 
	
	For Each TabularSection In ObjectMetadata.TabularSections Do // MetadataObjectTabularSection
		
		AttributesNames = AttributesList[TabularSection.Name];
		TSContent = DocumentReference[TabularSection.Name].Unload(); // ValueTable
		
		TSContent.GroupBy(AttributesNames);
		For Each TSColumn In TSContent.Columns Do
			For Each TSRow In TSContent Do
			
				AttributeValue = TSRow[TSColumn.Name];
				AttributeType = TypeOf(AttributeValue);
				AttributeMetadata = MetadataOfPropsType(AttributeType);
					
				If AttributeMetadata = Undefined Then
					Continue;
				EndIf;
				
				If Not ValueIsFilled(AttributeValue) Or AttributeValue = DocumentReference Then
					Continue;
				EndIf;
				
				ThisIsShippingDocument = ArrayOfShipmentTypes.Find(AttributeType) <> Undefined;
				ThisIsAcceptanceDocument = ArrayOfAcceptanceTypes.Find(AttributeType) <> Undefined;

				If (ThisIsShipment And ThisIsShippingDocument) 
					And ShippingDocuments.Find(AttributeValue) = Undefined Then
					ShippingDocuments.Add(AttributeValue);
				EndIf;
				
				If (ThisIsAcceptance And ThisIsAcceptanceDocument)
					And AcceptanceDocuments.Find(AttributeValue) = Undefined Then
					AcceptanceDocuments.Add(AttributeValue);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
   
	ParentalDocuments = New Structure;
	ParentalDocuments.Insert("ShippingDocuments", ShippingDocuments);
	ParentalDocuments.Insert("AcceptanceDocuments", AcceptanceDocuments);
	
	Return ParentalDocuments;
	
EndFunction

Function SubordinateDocuments(DocumentReference, ArrayOfShipmentTypes, ArrayOfAcceptanceTypes, ThisIsShipment, ThisIsAcceptance)
	
	ShippingDocuments = New Array;
	AcceptanceDocuments = New Array;
	
	TypePresentation = Common.TypePresentationString(TypeOf(DocumentReference));
	QueryText = MobileWarehouseKeeperWorkspaceCached.QueryTextOfRelatedDocuments(TypePresentation); 
	
	SubordinateDocuments = New Structure;
	SubordinateDocuments.Insert("ShippingDocuments", ShippingDocuments);
	SubordinateDocuments.Insert("AcceptanceDocuments", AcceptanceDocuments);

	If QueryText = Undefined Then 
		Return SubordinateDocuments;
	EndIf;
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentReference", DocumentReference);
	
	RelatedItemsTable = Query.Execute().Unload();
	If RelatedItemsTable = Undefined Then
		Return SubordinateDocuments;
	EndIf;
	
	For Each TableRow In RelatedItemsTable Do

		CurrentRef = TableRow.Ref; // DocumentRef
		
		If CurrentRef = DocumentReference Then
			Continue;
		EndIf;
		
		DocumentType = TypeOf(CurrentRef);
		
		ThisIsShippingDocument = ArrayOfShipmentTypes.Find(DocumentType) <> Undefined;
		ThisIsAcceptanceDocument = ArrayOfAcceptanceTypes.Find(DocumentType) <> Undefined;

		If (ThisIsShipment And ThisIsShippingDocument) 
			And ShippingDocuments.Find(CurrentRef) = Undefined Then
			ShippingDocuments.Add(CurrentRef);
		EndIf;
		
		If (ThisIsAcceptance And ThisIsAcceptanceDocument)
			And AcceptanceDocuments.Find(CurrentRef) = Undefined Then
			AcceptanceDocuments.Add(CurrentRef);
		EndIf;
		
	EndDo;
	
	SubordinateDocuments.ShippingDocuments = ShippingDocuments;
	SubordinateDocuments.AcceptanceDocuments = AcceptanceDocuments;

	Return SubordinateDocuments;

EndFunction

Function MetadataOfPropsType(AttributeType)
		
	Result = Undefined; 
	
	AttributeMetadata = Metadata.FindByType(AttributeType);
		
	If AttributeMetadata = Undefined Then
		Return Result;
	EndIf;

	If Not Common.MetadataObjectAvailableByFunctionalOptions(AttributeMetadata) 
		Or Not AccessRight("Read", AttributeMetadata) 
		Or Not Common.IsDocument(AttributeMetadata) Then
		Return Result;
	EndIf;
			
	Result = AttributeMetadata;
	Return Result;

EndFunction

Function ArrayOfOrderDocuments()
	
	ArrayOfOrderDocuments = New Array;
	
	
	ArrayOfOrderDocuments.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	ArrayOfOrderDocuments.Add(Type("DocumentRef.SubcontractOrder2_5"));
	ArrayOfOrderDocuments.Add(Type("DocumentRef.TransferOrder"));
	ArrayOfOrderDocuments.Add(Type("DocumentRef.PurchaseOrder"));
	ArrayOfOrderDocuments.Add(Type("DocumentRef.InventoryConsumptionOrder"));
	ArrayOfOrderDocuments.Add(Type("DocumentRef.SalesOrder"));
	ArrayOfOrderDocuments.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	
	Return ArrayOfOrderDocuments;

EndFunction

#EndRegion
#EndIf