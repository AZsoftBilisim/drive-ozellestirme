#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Premise,Status,WarehouseOperation,Date,RecordOfAPreviouslyReceivedLot";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//		Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//		Structure - the composition of the structure fields is set in the Nomenclature Clientserver function.Parameters of the Series specification.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = Documents.GoodsReceiptNote.SeriesSpecificationParameters(Object);
	
	SeriesSpecificationParameters.FullObjectName = "DataProcessor.GoodsQuantityCheckInGoodsReceiptNote";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order
//
// Parameters:
//  FieldValuesToIdentifyReferences	 - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
// 
// Returns:
//  DocumentRef - order.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	Return FieldValuesToIdentifyReferences.ReferenceOrder;	
EndFunction

// Returns a warehouse operation by order type.
//  If the order is not specified, the operation is considered "acceptance from the supplier"by default.
//
// Parameters:
//  ReferenceOrder - DocumentRef	 - link to the document-order for receipt of goods.
// 
// Returns:
//  EnumRef.WarehouseTransactions - warehouse operation of the order.
//
Function WarehouseOperationByOrder(ReferenceOrder) Export
	
	TypeOfOrder_ = TypeOf(ReferenceOrder);
	
	If Not ValueIsFilled(ReferenceOrder) Then
		
		Return Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient;
		
	ElsIf TypeOfOrder_ = Type("DocumentRef.PurchaseOrder")
		Or TypeOfOrder_ = Type("DocumentRef.VendorInvoice")
		Or TypeOfOrder_ = Type("DocumentRef.GoodsReceiptForStorage")
		Or TypeOfOrder_ = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		
		Return Enums.WarehouseTransactions.ReceiptFromVendor;
		
	ElsIf TypeOfOrder_ = Type("DocumentRef.ByAssemblyDisassemblyOrder")
		Or TypeOfOrder_ = Type("DocumentRef.AssemblyFromComponents") Then
		
		BusinessOperation = Common.ObjectAttributeValue(ReferenceOrder, "BusinessOperation");
		
		If BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
			Return Enums.WarehouseTransactions.ReceivingOfAssembledSets;
		Else
			Return Enums.WarehouseTransactions.ReceivingOfComponentsAfterDisassembly;
		EndIf;
		
	ElsIf TypeOfOrder_ = Type("DocumentRef.TransferOrder")
		Or TypeOfOrder_ = Type("DocumentRef.InventoryTransfer") Then
		
		Return Enums.WarehouseTransactions.ReceivingByTransfer;
		
	ElsIf TypeOfOrder_ = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
		Or TypeOfOrder_ = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		Return Enums.WarehouseTransactions.ReceivingByReturnFromACustomer;
		
	ElsIf TypeOfOrder_ = Type("DocumentRef.OtherGoodsRecordingAsReceived")
		Then
		
		Return Enums.WarehouseTransactions.GoodsReceiptByOtherTransactions;
	ElsIf TypeOfOrder_ = Type("DocumentRef.MovementOfProductsAndMaterials") 
		Then
		
		Return Enums.WarehouseTransactions.ProductReceivingFromManufacturing;
	Else
		
		Return Enums.WarehouseTransactions.ReceiptFromVendor;
		
	EndIf;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText =
	"SELECT
	|	Goods.Products,
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		ELSE CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|					THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN CASE
	|										WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|											THEN 14
	|										ELSE 10
	|									END
	|							WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|									AND &OrderPreparation
	|								THEN 11
	|							ELSE CASE
	|									WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|										THEN 13
	|									ELSE 9
	|								END
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|								THEN CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 6
	|										WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|												AND &OrderPreparation
	|											THEN 11
	|										ELSE 5
	|									END
	|							ELSE CASE
	|									WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|										THEN 8
	|									WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|											AND &OrderPreparation
	|										THEN 11
	|									ELSE 7
	|								END
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|								THEN CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 4
	|										WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|												AND &OrderPreparation
	|											THEN 11
	|										ELSE 3
	|									END
	|							ELSE CASE
	|									WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|										THEN 2
	|									WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|											AND &OrderPreparation
	|										THEN 11
	|									ELSE 1
	|								END
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|INTO StatusTable
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON (CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref)
	|			AND (BatchAccountingPolicies.Warehouse = &Warehouse)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusTable.LineNumber AS LineNumber,
	|	StatusTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	StatusTable AS StatusTable
	|WHERE
	|	StatusTable.OldStatusOfSpecifyingSeries <> StatusTable.BatchesIndicationStatus
	|
	|ORDER BY
	|	LineNumber";
	
	ThisIsReturnOfRejectedGoods = SeriesSpecificationParameters.WarehouseTransactions
		.Find(Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient) <> Undefined;
	ThisReturnOfUnrecognizedGoodsIsOutdated = SeriesSpecificationParameters.WarehouseTransactions
		.Find(Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipientNotUsed) <> Undefined;
	
	If ThisIsReturnOfRejectedGoods
		Or ThisReturnOfUnrecognizedGoodsIsOutdated Then
		
		QueryText = StrReplace(QueryText,"BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving",
			"BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipment");
			
	Else
		QueryText = StrReplace(QueryText,"BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving",
			"BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
			|						AND (BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingFromVendor
			|								AND &ReceiptFromVendor
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByReturnFromCustomer
			|								AND &ReceivingByReturnFromACustomer
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingProductsFromManufacturing
			|								AND &ProductReceivingFromManufacturing
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByTransfer
			|								AND &ReceivingByTransfer
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByOtherRecordingAsReceived
			|								AND &GoodsReceiptByOtherTransactions
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingComponentsAfterDisassembly
			|								AND &ReceivingOfComponentsAfterDisassembly
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingAssembledKits
			|								AND &ReceivingOfAssembledSets)");
	EndIf;

	Return QueryText;
	
EndFunction

// Returns the request body for the get the available appointments
//	Parameters:
//		RequestFormationParameters - Structure - the parameters for the generation of text queries
//	Returns:
//		String - query text.
//
Function RequestTextForAvailableAssignments(RequestFormationParameters) Export
	
	Return Documents.GoodsReceiptNote.RequestTextForAvailableAssignments(RequestFormationParameters);
	
EndFunction

#EndRegion

#EndIf
