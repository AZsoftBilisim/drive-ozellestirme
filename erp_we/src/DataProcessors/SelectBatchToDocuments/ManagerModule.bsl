#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function TextOfRequestToGenerateTableRegisterData(OptionOfDataReceivingFromRegisters, WarehouseOrDepartment = Undefined) Export
	
	If OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesFromRemainder" Then
		
		If WarehouseOrDepartment = Undefined Or TypeOf(WarehouseOrDepartment) <> Type("CatalogRef.BusinessStructure") Then
			
			// Any non-reserved series can be specified in the invoice (or order)
			// You need to subtract the reserves of the series from the remainder of the series.
			
			QueryText = 
			"SELECT ALLOWED
			|	DataOfRegister.Series AS Series,
			|	SUM(DataOfRegister.AvailableStock) AS AvailableStock
			|INTO RegisterDataForRequest
			|FROM
			|	(SELECT
			|		ProductStockBalance.Series AS Series,
			|		ProductStockBalance.InStockBalance AS AvailableStock
			|	FROM
			|		AccumulationRegister.ProductStock.Balance(
			|				,
			|				Products = &Products
			|					AND Characteristic = &Characteristic
			|					AND (Purpose = &Purpose
			|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
			|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
			|					AND Warehouse = &Warehouse
			|					AND ControlledLotReference = &ControlledLotReference) AS ProductStockBalance
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsForIssueBalance.Series,
			|		-GoodsForIssueBalance.ToShipBalance - GoodsForIssueBalance.InReserveBalance
			|	FROM
			|		AccumulationRegister.GoodsForIssue.Balance(
			|				,
			|				Products = &Products
			|					AND Warehouse = &Warehouse
			|					AND Characteristic = &Characteristic
			|					AND (Purpose = &Purpose
			|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
			|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
			|					AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
			|					AND ControlledLotReference = &ControlledLotReference) AS GoodsForIssueBalance
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		ProductStock.Series,
			|		CASE
			|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN -ProductStock.InStock + ProductStock.ToShip
			|			ELSE ProductStock.InStock - ProductStock.ToShip
			|		END
			|	FROM
			|		AccumulationRegister.ProductStock AS ProductStock
			|	WHERE
			|		ProductStock.Products = &Products
			|		AND ProductStock.Characteristic = &Characteristic
			|		AND (ProductStock.Purpose = &Purpose
			|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
			|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
			|		AND ProductStock.Warehouse = &Warehouse
			|		AND ProductStock.ControlledLotReference = &ControlledLotReference
			|		AND ProductStock.Recorder = &Recorder
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		SeriesReserves.Series,
			|		CASE
			|			WHEN SeriesReserves.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN SeriesReserves.ToShip + SeriesReserves.InReserve
			|			ELSE -SeriesReserves.ToShip - SeriesReserves.InReserve
			|		END
			|	FROM
			|		AccumulationRegister.GoodsForIssue AS SeriesReserves
			|	WHERE
			|		SeriesReserves.Products = &Products
			|		AND SeriesReserves.Characteristic = &Characteristic
			|		AND (SeriesReserves.Purpose = &Purpose
			|						OR SeriesReserves.Purpose = VALUE(Catalog.Assignments.EmptyRef)
			|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
			|		AND SeriesReserves.Warehouse = &Warehouse
			|		AND SeriesReserves.ControlledLotReference = &ControlledLotReference
			|		AND SeriesReserves.Recorder = &Recorder
			|		AND SeriesReserves.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)) AS DataOfRegister
			|
			|GROUP BY
			|	DataOfRegister.Series";
		Else
				
			// Any non-reserved series can be specified in the invoice (or order)
			// You need to subtract the reserves of the series from the remainder of the series.
			
			QueryText = 
			"SELECT ALLOWED
			|	DataOfRegister.Series AS Series,
			|	SUM(DataOfRegister.AvailableStock) AS AvailableStock
			|INTO RegisterDataForRequest
			|FROM
			|	(SELECT
			|		MaterialsAndWorksInProduction.Series AS Series,
			|		MaterialsAndWorksInProduction.CountBalance AS AvailableStock
			|	FROM
			|		AccumulationRegister.MaterialsAndWorksInProduction.Balance(
			|				,
			|				Products = &Products
			|					AND Characteristic = &Characteristic
			|					AND (Purpose = &Purpose
			|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
			|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
			|					AND Department = &Warehouse) AS MaterialsAndWorksInProduction
			|
			|	UNION ALL
			|	
			|	SELECT
			|		MaterialsAndWorksInProduction.Series,
			|		CASE
			|			WHEN MaterialsAndWorksInProduction.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN -MaterialsAndWorksInProduction.Count
			|			ELSE MaterialsAndWorksInProduction.Count
			|		END
			|	FROM
			|		AccumulationRegister.MaterialsAndWorksInProduction AS MaterialsAndWorksInProduction
			|	WHERE
			|		MaterialsAndWorksInProduction.Products = &Products
			|		AND MaterialsAndWorksInProduction.Characteristic = &Characteristic
			|		AND (MaterialsAndWorksInProduction.Purpose = &Purpose
			|						OR MaterialsAndWorksInProduction.Purpose = VALUE(Catalog.Assignments.EmptyRef)
			|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
			|		AND MaterialsAndWorksInProduction.Department = &Warehouse
			|		AND MaterialsAndWorksInProduction.Recorder = &Recorder) AS DataOfRegister
			|
			|GROUP BY
			|	DataOfRegister.Series";
		EndIf; 
		
	ElsIf OptionOfDataReceivingFromRegisters = "InvoiceOfSeriesFromOrder" Then
		
		// Only the series specified in the order, for which invoices have not yet been issued, can be indicated in the invoice
		// It is necessary to take the remaining reserves of the series on order.
		
		QueryText = 
		"SELECT ALLOWED  
		|	DataOfRegister.Series AS Series,
		|	SUM(DataOfRegister.AvailableStock) AS AvailableStock
		|INTO RegisterDataForRequest
		|FROM
		|	(SELECT
		|		GoodsForIssueBalance.Series AS Series,
		|		GoodsForIssueBalance.ToRegisterBalance AS AvailableStock
		|	FROM
		|		AccumulationRegister.GoodsForIssue.Balance(
		|				,
		|				Products = &Products
		|					AND Warehouse = &Warehouse
		|					AND Characteristic = &Characteristic
		|					AND (Purpose = &Purpose
		|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|					AND DocumentShipments = &ReferenceOrder
		|					AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|					AND ControlledLotReference = &ControlledLotReference) AS GoodsForIssueBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesReserves.Series,
		|		CASE
		|			WHEN SeriesReserves.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -SeriesReserves.ToRegister
		|			ELSE SeriesReserves.ToRegister
		|		END
		|	FROM
		|		AccumulationRegister.GoodsForIssue AS SeriesReserves
		|	WHERE
		|		SeriesReserves.Products = &Products
		|		AND SeriesReserves.Characteristic = &Characteristic
		|		AND (SeriesReserves.Purpose = &Purpose
		|						OR SeriesReserves.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|		AND SeriesReserves.Warehouse = &Warehouse
		|		AND SeriesReserves.Recorder = &Recorder
		|		AND SeriesReserves.DocumentShipments = &ReferenceOrder
		|		AND SeriesReserves.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND SeriesReserves.ControlledLotReference = &ControlledLotReference) AS DataOfRegister
		|
		|GROUP BY
		|	DataOfRegister.Series";
		
	ElsIf OptionOfDataReceivingFromRegisters = "OrderSeriesFromRemainder" Then
		
		// Any series that are on the balance can be specified in the order (not yet specified in other orders)
		// This option can also be used in retail documents.
		
		QueryText = 
		"SELECT ALLOWED
		|	DataOfRegister.Series AS Series,
		|	SUM(DataOfRegister.AvailableStock) AS AvailableStock
		|INTO RegisterDataForRequest
		|FROM
		|	(SELECT
		|		ProductStockBalance.Series AS Series,
		|		ProductStockBalance.InStockBalance - ProductStockBalance.ToShipBalance AS AvailableStock
		|	FROM
		|		AccumulationRegister.ProductStock.Balance(
		|				,
		|				Products = &Products
		|					AND Characteristic = &Characteristic
		|					AND (Purpose = &Purpose
		|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|					AND Warehouse = &Warehouse
		|					AND Premise = &Premise
		|					AND ControlledLotReference = &ControlledLotReference) AS ProductStockBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ProductStock.Series,
		|		CASE
		|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ProductStock.InStock + ProductStock.ToShip
		|			ELSE ProductStock.InStock - ProductStock.ToShip
		|		END
		|	FROM
		|		AccumulationRegister.ProductStock AS ProductStock
		|	WHERE
		|		ProductStock.Products = &Products
		|		AND ProductStock.Characteristic = &Characteristic
		|		AND (ProductStock.Purpose = &Purpose
		|						OR ProductStock.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|		AND ProductStock.Warehouse = &Warehouse
		|		AND ProductStock.Premise = &Premise
		|		AND ProductStock.ControlledLotReference = &ControlledLotReference
		|		AND ProductStock.Recorder = &Recorder) AS DataOfRegister
		|
		|GROUP BY
		|	DataOfRegister.Series";
		
	ElsIf OptionOfDataReceivingFromRegisters = "OrderSeriesFromInvoice" Then
		
		// If the series are specified in the invoice, then only those series that are in the invoice can be specified in the order
		// The information from the invoice to the order about which series to ship is transmitted through the register "Goods for Shipment",
		// it also records that the series is already specified in the order, therefore, to obtain information about which series in the invoice
		// , you need to use the register "Goods for Shipment"
		// The invoice reserves the series as a whole for the warehouse without taking into account the premises, but it is impossible to specify more in the order
		// than there is in the room - therefore, it is necessary to additionally analyze the register of "Goods in the warehouse".
		
		QueryText = 
		"SELECT ALLOWED
		|	DataFromGoodsForShipmentRegister.Series AS Series,
		|	SUM(DataFromGoodsForShipmentRegister.AvailableStock) AS AvailableStock
		|INTO DataFromGoodsForShipmentRegister
		|FROM
		|	(SELECT
		|		GoodsForIssueBalance.Series AS Series,
		|		GoodsForIssueBalance.ToShipBalance - GoodsForIssueBalance.AssemblyInProgressBalance - GoodsForIssueBalance.AssembledBalance AS AvailableStock
		|	FROM
		|		AccumulationRegister.GoodsForIssue.Balance(
		|				,
		|				DocumentShipments = &ReferenceOrder
		|					AND Characteristic = &Characteristic
		|					AND Products = &Products
		|					AND (Purpose = &Purpose
		|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|					AND Warehouse = &Warehouse
		|					AND ControlledLotReference = &ControlledLotReference
		|					AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)) AS GoodsForIssueBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsForIssue.Series,
		|		CASE
		|			WHEN GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -GoodsForIssue.ToShip + GoodsForIssue.AssemblyInProgress + GoodsForIssue.Assembled
		|			ELSE GoodsForIssue.ToShip - GoodsForIssue.AssemblyInProgress - GoodsForIssue.Assembled
		|		END
		|	FROM
		|		AccumulationRegister.GoodsForIssue AS GoodsForIssue
		|	WHERE
		|		GoodsForIssue.Products = &Products
		|		AND GoodsForIssue.Characteristic = &Characteristic
		|		AND (GoodsForIssue.Purpose = &Purpose
		|						OR GoodsForIssue.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|		AND GoodsForIssue.Warehouse = &Warehouse
		|		AND GoodsForIssue.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND GoodsForIssue.Recorder = &Recorder
		|		AND GoodsForIssue.DocumentShipments = &ReferenceOrder) AS DataFromGoodsForShipmentRegister
		|
		|GROUP BY
		|	DataFromGoodsForShipmentRegister.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	RegisterDataGoodsInWarehouses.Series AS Series,
		|	SUM(RegisterDataGoodsInWarehouses.AvailableStock) AS AvailableStock
		|INTO RegisterDataGoodsInWarehouses
		|FROM
		|	(SELECT
		|		ProductStockBalance.Series AS Series,
		|		ProductStockBalance.InStockBalance - ProductStockBalance.ToShipBalance AS AvailableStock
		|	FROM
		|		AccumulationRegister.ProductStock.Balance(
		|				,
		|				Products = &Products
		|					AND Characteristic = &Characteristic
		|					AND (Purpose = &Purpose
		|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|					AND Warehouse = &Warehouse
		|					AND Premise = &Premise
		|					AND ControlledLotReference = &ControlledLotReference) AS ProductStockBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ProductStock.Series,
		|		CASE
		|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ProductStock.InStock + ProductStock.ToShip
		|			ELSE ProductStock.InStock - ProductStock.ToShip
		|		END
		|	FROM
		|		AccumulationRegister.ProductStock AS ProductStock
		|	WHERE
		|		ProductStock.Products = &Products
		|		AND ProductStock.Characteristic = &Characteristic
		|		AND (ProductStock.Purpose = &Purpose
		|						OR ProductStock.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|		AND ProductStock.Warehouse = &Warehouse
		|		AND ProductStock.Premise = &Premise
		|		AND ProductStock.ControlledLotReference = &ControlledLotReference
		|		AND ProductStock.Recorder = &Recorder) AS RegisterDataGoodsInWarehouses
		|
		|GROUP BY
		|	RegisterDataGoodsInWarehouses.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	DataFromGoodsForShipmentRegister.Series,
		|	CASE
		|		WHEN DataFromGoodsForShipmentRegister.AvailableStock < ISNULL(RegisterDataGoodsInWarehouses.AvailableStock, 0)
		|			THEN DataFromGoodsForShipmentRegister.AvailableStock
		|		ELSE ISNULL(RegisterDataGoodsInWarehouses.AvailableStock, 0)
		|	END AS AvailableStock
		|INTO RegisterDataForRequest
		|FROM
		|	DataFromGoodsForShipmentRegister AS DataFromGoodsForShipmentRegister
		|		LEFT JOIN RegisterDataGoodsInWarehouses AS RegisterDataGoodsInWarehouses
		|		ON DataFromGoodsForShipmentRegister.Series = RegisterDataGoodsInWarehouses.Series";
		
	ElsIf OptionOfDataReceivingFromRegisters = "GoodsInStorageBins" Then
		
		QueryText = 
		"SELECT ALLOWED
		|	RegisterData.Series AS Series,
		|	SUM(RegisterData.AvailableStock) AS AvailableStock
		|INTO RegisterDataForRequest
		|FROM
		|	(SELECT
		|		GoodsInStorageBinsBalance.Series AS Series,
		|		GoodsInStorageBinsBalance.InStockBalance - GoodsInStorageBinsBalance.ForPickingBalance AS AvailableStock
		|	FROM
		|		AccumulationRegister.GoodsInStorageBins.Balance(
		|				,
		|				Cell = &Cell
		|					AND Package = &Package
		|					AND Characteristic = &Characteristic
		|					AND (Purpose = &Purpose
		|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|					AND Products = &Products) AS GoodsInStorageBinsBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsInStorageBins.Series,
		|		CASE
		|			WHEN GoodsInStorageBins.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -GoodsInStorageBins.InStock + GoodsInStorageBins.ForPicking
		|			ELSE GoodsInStorageBins.InStock - GoodsInStorageBins.ForPicking
		|		END
		|	FROM
		|		AccumulationRegister.GoodsInStorageBins AS GoodsInStorageBins
		|	WHERE
		|		GoodsInStorageBins.Products = &Products
		|		AND GoodsInStorageBins.Characteristic = &Characteristic
		|		AND (GoodsInStorageBins.Purpose = &Purpose
		|						OR GoodsInStorageBins.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|		AND GoodsInStorageBins.Package = &Package
		|		AND GoodsInStorageBins.Recorder = &Recorder
		|		AND GoodsInStorageBins.Cell = &Cell) AS RegisterData
		|
		|GROUP BY
		|	RegisterData.Series";
		
	ElsIf OptionOfDataReceivingFromRegisters = "GoodsReadyForReceipt" Then
		
		QueryText = 
		"SELECT ALLOWED
		|	DataOfRegister.Series AS Series,
		|	SUM(DataOfRegister.AvailableStock) AS AvailableStock
		|INTO RegisterDataForRequest
		|FROM
		|	(SELECT
		|		GoodsReadyForReceiptBalance.Series AS Series,
		|		GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance AS AvailableStock
		|	FROM
		|		AccumulationRegister.GoodsToReceive.Balance(
		|				,
		|				Products = &Products
		|					AND Warehouse = &Warehouse
		|					AND Characteristic = &Characteristic
		|					AND (Purpose = &Purpose
		|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|					AND DocumentInflow = &ReferenceOrder
		|					AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|					AND ControlledLotReference = &ControlledLotReference) AS GoodsReadyForReceiptBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsReadyForReceipt.Series,
		|		CASE
		|			WHEN GoodsReadyForReceipt.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -GoodsReadyForReceipt.ToRegisterGoodsReceipts
		|			ELSE GoodsReadyForReceipt.ToRegisterGoodsReceipts
		|		END
		|	FROM
		|		AccumulationRegister.GoodsToReceive AS GoodsReadyForReceipt
		|	WHERE
		|		GoodsReadyForReceipt.Products = &Products
		|		AND GoodsReadyForReceipt.Characteristic = &Characteristic
		|		AND (GoodsReadyForReceipt.Purpose = &Purpose
		|						OR GoodsReadyForReceipt.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|		AND GoodsReadyForReceipt.Warehouse = &Warehouse
		|		AND GoodsReadyForReceipt.Recorder = &Recorder
		|		AND GoodsReadyForReceipt.DocumentInflow = &ReferenceOrder
		|		AND GoodsReadyForReceipt.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND GoodsReadyForReceipt.ControlledLotReference = &ControlledLotReference
		|) AS DataOfRegister
		|
		|GROUP BY
		|	DataOfRegister.Series";
		
	ElsIf OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesOnBalancesWithKeeper"
		Or OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesOnBalancesWithCommissionAgent" Then
		
		QueryText = 
		"SELECT ALLOWED
		|	Analysts.DimensionKey AS Ref
		|INTO TTProductAccountingAnalytics
		|FROM
		|	InformationRegister.ItemsLocationAttributes AS Analysts
		|WHERE
		|	Products = &Products
		|	AND Characteristic = &Characteristic
		|	AND StorageLocation = &Warehouse
		|	AND (Purpose = &Purpose
		|		OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|	AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|
		|;
		|
		|SELECT ALLOWED
		|	DataOfRegister.Series AS Series,
		|	SUM(DataOfRegister.AvailableStock) AS AvailableStock
		|INTO RegisterDataForRequest
		|FROM
		|	(SELECT
		|		CompanyGoodsBalance.ItemsLocationAttributes.Series AS Series,
		|		CompanyGoodsBalance.CountBalance AS AvailableStock
		|	FROM
		|		AccumulationRegister.CompanyGoods.Balance(, ItemsLocationAttributes IN 
		|			(SELECT
		|				Dimension.Ref
		|			FROM
		|				TTProductAccountingAnalytics AS Dimension
		|			)
		|		) AS CompanyGoodsBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CompanyGoodsBalance.ItemsLocationAttributes.Series,
		|		CASE
		|			WHEN CompanyGoodsBalance.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -CompanyGoodsBalance.Count
		|			ELSE CompanyGoodsBalance.Count
		|		END
		|	FROM
		|		AccumulationRegister.CompanyGoods AS CompanyGoodsBalance
		|		LEFT JOIN TTProductAccountingAnalytics AS Dimension
		|		ON CompanyGoodsBalance.ItemsLocationAttributes = Dimension.Ref
		|	WHERE
		|		NOT Dimension.Ref IS NULL
		|		AND CompanyGoodsBalance.Recorder = &Recorder
		|		AND CompanyGoodsBalance.ItemsLocationAttributes.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|
		|	) AS DataOfRegister
		|
		|GROUP BY
		|	DataOfRegister.Series";
		
	ElsIf OptionOfDataReceivingFromRegisters = "OrderIsSeriesInvoiceForCommitteeSBalances" Then
		
		QueryText = 
		"SELECT ALLOWED
		|	Analysts.DimensionKey AS Ref,
		|	InventoryKinds.Organization AS Organization,
		|	InventoryKinds.Ref AS InventoryOwnerAttribute
		|INTO TTProductAccountingAnalytics
		|FROM
		|	InformationRegister.ItemsLocationAttributes AS Analysts
		|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|		AND InventoryKinds.Organization = &Organization
		|		AND InventoryKinds.GoodsOwner = &Partner
		|WHERE
		|	Analysts.Products = &Products
		|	AND Analysts.Characteristic = &Characteristic
		|	AND Analysts.StorageLocation = &Warehouse
		|	AND (Analysts.Purpose = &Purpose
		|	OR Analysts.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|	AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|	AND Analysts.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	DataOfRegister.Series AS Series,
		|	SUM(DataOfRegister.AvailableStock) AS AvailableStock
		|INTO RegisterDataForRequest
		|FROM
		|	(SELECT
		|		CompanyGoodsBalance.ItemsLocationAttributes.Series AS Series,
		|		CompanyGoodsBalance.CountBalance AS AvailableStock
		|	FROM
		|		AccumulationRegister.CompanyGoods.Balance(, (ItemsLocationAttributes, Organization, InventoryOwnerAttribute) IN
		|			(SELECT
		|				Dimension.Ref,
		|				Dimension.Organization,
		|				Dimension.InventoryOwnerAttribute
		|			FROM
		|				TTProductAccountingAnalytics AS Dimension)) AS CompanyGoodsBalance
		|
		|	UNION ALL
		|
		|	SELECT
		|		CompanyGoodsBalance.ItemsLocationAttributes.Series,
		|		CASE
		|			WHEN CompanyGoodsBalance.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -CompanyGoodsBalance.Count
		|			ELSE CompanyGoodsBalance.Count
		|		END
		|	FROM
		|		AccumulationRegister.CompanyGoods AS CompanyGoodsBalance
		|			LEFT JOIN TTProductAccountingAnalytics AS Dimension
		|			ON CompanyGoodsBalance.ItemsLocationAttributes = Dimension.Ref
		|			AND CompanyGoodsBalance.Organization = Dimension.Organization
		|			AND CompanyGoodsBalance.InventoryOwnerAttribute = Dimension.InventoryOwnerAttribute
		|	WHERE
		|		NOT Dimension.Ref IS NULL
		|		AND CompanyGoodsBalance.Recorder = &Recorder
		|		AND CompanyGoodsBalance.ItemsLocationAttributes.Series
		|			<> VALUE(Catalog.ItemsBatches.EmptyRef)) AS
		|		DataOfRegister
		|GROUP BY
		|	DataOfRegister.Series";
	
	ElsIf OptionOfDataReceivingFromRegisters = "GoodsInWarehousesWithoutDestination" Then
		
		// Used in the Nomenclature certificate.The form of the selection of the plastidefactionseries
		
		QueryText = 
		"SELECT ALLOWED
		|		ProductStockBalance.Series AS Series,
		|		ProductStockBalance.InStockBalance - ProductStockBalance.ToShipBalance AS AvailableStock
		|INTO RegisterDataForRequest
		|	FROM
		|		AccumulationRegister.ProductStock.Balance(
		|				,
		|				Products = &Products
		|					AND Characteristic = &Characteristic
		|					AND Warehouse = &Warehouse
		|					AND Premise = &Premise
		|					AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)) AS ProductStockBalance";
		
	ElsIf OptionOfDataReceivingFromRegisters <> "AllSeriesProducts" Then
		
		Raise NStr("vi = 'Không hỗ trợ phương án nhận dữ liệu theo sê-ri.';
					|ru = 'Неподдерживаемый вариант получения данных по сериям.';
					|en = 'Unsupported option of batch data receipt.'; fa = 'Unsupported option of batch data receipt.';
					|it = 'Opzione non supportata per ottenere i dati relativi alle serie.';
					|pl = 'Nieobsługiwana opcja pobierania danych dla serii.';
					|tr = 'Parti verilerini almak için desteklenmeyen seçenek.'");
		
	EndIf;
	
	ThereIsRightToReadRegisteredRecords = AccessRight("Read",Metadata.AccumulationRegisters.GoodsBatchMovement);
	
	If OptionOfDataReceivingFromRegisters = "AllSeriesProducts" Then
		If ThereIsRightToReadRegisteredRecords Then
			QueryText = 
			"SELECT ALLOWED DISTINCT
			|	GoodsBatchMovement.Series,
			|	0 AS AvailableStock
			|INTO DataOfRegister
			|FROM
			|	AccumulationRegister.GoodsBatchMovement AS GoodsBatchMovement
			|WHERE
			|	GoodsBatchMovement.Products = &Products
			|	AND GoodsBatchMovement.Characteristic = &Characteristic";
		Else
			QueryText = 
			"SELECT
			|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
			|	0 AS AvailableStock
			|INTO DataOfRegister
			|WHERE
			|	FALSE";
		EndIf;
	Else
		
		QueryParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(QueryText, "AccumulationRegister.");
		QueryParts.Delete(0);
		CheckedRegisters = New Map;
		For Each PartOfRequest In QueryParts Do
			RegisterName = StrSplit(PartOfRequest, "."+" "+Chars.LF+Chars.NBSp)[0];
			If CheckedRegisters[RegisterName] = Undefined Then
				CheckedRegisters.Insert(RegisterName);
				If Not AccessRight("Read",Metadata.AccumulationRegisters[RegisterName]) Then
					QueryText = 
					"SELECT
					|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
					|	0 AS AvailableStock
					|INTO RegisterDataForRequest
					|WHERE
					|	FALSE";
					
					Break;
					
				EndIf;
			EndIf;
		EndDo;
	
		QueryText = QueryText + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		If ThereIsRightToReadRegisteredRecords Then
			
			QueryText = QueryText + 
			"SELECT ALLOWED DISTINCT
			|	GoodsBatchMovement.Series
			|INTO AllSeries
			|FROM
			|	AccumulationRegister.GoodsBatchMovement AS GoodsBatchMovement
			|WHERE
			|	GoodsBatchMovement.Products = &Products
			|	AND GoodsBatchMovement.Characteristic = &Characteristic
			|	AND &AllSeries
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	NestedQuery.Series AS Series,
			|	SUM(NestedQuery.AvailableStock) AS AvailableStock
			|INTO DataOfRegister
			|FROM
			|	(SELECT
			|		GoodsBatchMovement.Series AS Series,
			|		0 AS AvailableStock
			|	FROM
			|		AllSeries AS GoodsBatchMovement
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RegisterDataForRequest.Series,
			|		RegisterDataForRequest.AvailableStock
			|	FROM
			|		RegisterDataForRequest AS RegisterDataForRequest) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Series";
		Else
			QueryText = QueryText + 
			"SELECT
			|	RegisterDataForRequest.Series,
			|	RegisterDataForRequest.AvailableStock
			|INTO DataOfRegister
			|FROM
			|	RegisterDataForRequest AS RegisterDataForRequest";
		EndIf;
	EndIf;
	
	Return QueryText;
	
EndFunction

Function ThereAreRightsToReadRegisterData(OptionOfDataReceivingFromRegisters, WarehouseOrDepartment) Export
	
	QueryText = TextOfRequestToGenerateTableRegisterData(OptionOfDataReceivingFromRegisters, WarehouseOrDepartment);
	ThereAreRightsToReadRegisterData = StrFind(QueryText,"AccumulationRegister.") <> 0
		And AccessRight("Read",Metadata.AccumulationRegisters.GoodsBatchMovement);
	
	Return ThereAreRightsToReadRegisterData;
	
EndFunction

Function OptionGettingDataFromRegistersByFormParameters(SeriesSpecificationParameters, ReferenceOrder, Warehouse, ProductKind) Export
	
	AccountingPolicyParametersOfSeries = New FixedStructure(Catalogs.ItemKinds.SeriesUseSettings(
																											ProductKind,
																											SeriesSpecificationParameters,
																											New Structure("Warehouse", Warehouse)));
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.RetailShipment) <> Undefined Then
		// This form does not come off from the expense orders, so this warehouse operation can only 
		// be in the report of retail sales, receipts, and input of items.
		
		If AccountingPolicyParametersOfSeries.AccountForRemainingSeries Then	
			OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesFromRemainder";
		Else
			OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
		EndIf;
	ElsIf SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.OBEntry) <> Undefined Then
		
		OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
		
	ElsIf SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer) <> Undefined
		And SeriesSpecificationParameters.FullObjectName <> Metadata.Documents.GoodsReceiptFromCustomer.FullName()
		And SeriesSpecificationParameters.FullObjectName <> Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName() Then
		
		OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
		
	ElsIf SeriesSpecificationParameters.NameOfSenderWarehouseField <> Undefined
			And SeriesSpecificationParameters.NameOfRecipientWarehouseField <> Undefined Then //this is the movement of goods
		
		If AccountingPolicyParametersOfSeries.AccountForRemainingSeries Then
			If AccountingPolicyParametersOfSeries.SpecifyWhenPlanningShipment 
				And ValueIsFilled(ReferenceOrder) Then
				OptionOfDataReceivingFromRegisters = "InvoiceOfSeriesFromOrder";
			Else
				OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesFromRemainder";
			EndIf;
		Else
			OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
		EndIf;
		
	ElsIf SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient) <> Undefined Then
		OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
		
	ElsIf SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.TransferInventoryInOperation) <> Undefined
		Or SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.RecordInventoryInOperation) <> Undefined
		Or SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.PhysicalCountOfInventoryInOperation) <> Undefined Then
		
		OptionOfDataReceivingFromRegisters = "ConsignmentNoteOfSeriesFromRemainderOfTMTSVOperation";
		
	ElsIf ReferenceOrder <> Undefined
		And Enums.WarehouseTransactions.ThereIsAcceptance(SeriesSpecificationParameters.WarehouseTransactions) Then
		
		ThisIsAdmissionOrder = True;
		ThisIsAdmissionOrder = TypeOf(ReferenceOrder) <> Type("DocumentRef.ProductionStage2_2");
		If ThisIsAdmissionOrder
			And WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Warehouse,SeriesSpecificationParameters.Date)
			And AccountingPolicyParametersOfSeries.UseCostAccountingByBatches Then
			OptionOfDataReceivingFromRegisters = "GoodsReadyForReceipt";
		Else
			OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
		EndIf;
		
	ElsIf SeriesSpecificationParameters.FullObjectName = Metadata.Documents.RedemptionOfGoodsByCustodian.FullName()
		Or SeriesSpecificationParameters.FullObjectName = Metadata.Documents.GoodsReceiptFromCustomer.FullName()
		Or (SeriesSpecificationParameters.FullObjectName = Metadata.Documents.CustomerInvoice.FullName()
			And SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.TransferOfTitleToGoods)
		Or (SeriesSpecificationParameters.FullObjectName = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName()
			And SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.ReturnFromCustodian)
		Or (SeriesSpecificationParameters.FullObjectName = Metadata.Documents.SubcontractorReport2_5.FullName()
			And Not SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.MovementInFinancialAccounting) = Undefined)
		Or (SeriesSpecificationParameters.FullObjectName = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName()
			And Not SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceiptFromVendor) = Undefined)
		Or (SeriesSpecificationParameters.FullObjectName = Metadata.Documents.WriteOffOfShippedGoods.FullName()
			And SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.WriteOffShortagesAtDepositorSExpense
				Or SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.WriteOffOfShippedGoods) Then
		
		OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesOnBalancesWithKeeper";
		
	ElsIf SeriesSpecificationParameters.FullObjectName = Metadata.Documents.ConsignmentReportFromCustomer.FullName()
		Or (SeriesSpecificationParameters.FullObjectName = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName()
			And SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.ReturnFromCommissionAgent)
		Or (SeriesSpecificationParameters.FullObjectName = Metadata.Documents.WriteOffOfShippedGoods.FullName()
			And SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense) Then
		
		OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesOnBalancesWithCommissionAgent";
		
	ElsIf (SeriesSpecificationParameters.FullObjectName = Metadata.Documents.ReturnOfGoodsToVendor.FullName()
			And SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.ReturnOfGoodsToConsignor) Then
		
		OptionOfDataReceivingFromRegisters = "OrderIsSeriesInvoiceForCommitteeSBalances";
		
	ElsIf SeriesSpecificationParameters.ThisIsOrder
		Or (SeriesSpecificationParameters.ThisIsAnInvoice
		And (Not ValueIsFilled(ReferenceOrder)
		Or Not AccountingPolicyParametersOfSeries.SpecifyWhenPlanningShipment))
		And SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.OBEntry) = Undefined 
		And SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer) = Undefined 
		And SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.EmptyRef()) = Undefined Then
		
		If AccountingPolicyParametersOfSeries.AccountForRemainingSeries
			And Not Enums.WarehouseTransactions.ThereIsAcceptance(SeriesSpecificationParameters.WarehouseTransactions) Then
			OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesFromRemainder";
		Else
			OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
		EndIf;
		
	ElsIf SeriesSpecificationParameters.ThisIsAnInvoice
		And ValueIsFilled(ReferenceOrder) Then
		
		If AccountingPolicyParametersOfSeries.AccountForRemainingSeries
			And AccountingPolicyParametersOfSeries.SpecifyWhenPlanningShipment Then
			If Not SalesServer.UseCustomerOrderAsInvoice(ReferenceOrder) Then
				OptionOfDataReceivingFromRegisters = "InvoiceOfSeriesFromOrder";
			Else
				OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesFromRemainder";
			EndIf;
		Else
			OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
		EndIf;
		
	Else
		If AccountingPolicyParametersOfSeries.AccountForRemainingSeries
			And SeriesSpecificationParameters.FullObjectName <> Metadata.Documents.CustomerInvoiceIntercompany.FullName() Then
			If SeriesSpecificationParameters.ItSWarrant Then
				If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.TransferBetweenWarerooms) <> Undefined
					Or Not AccountingPolicyParametersOfSeries.SpecifyWhenPlanningShipment
					Or Not ValueIsFilled(ReferenceOrder) Then
					OptionOfDataReceivingFromRegisters = "OrderSeriesFromRemainder";
				Else
					OptionOfDataReceivingFromRegisters = "OrderSeriesFromInvoice";
				EndIf;
			ElsIf SeriesSpecificationParameters.FullObjectName <> "Document.RedemptionOfGoodsFromStorage"
				Then
				
				OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesFromRemainder";
			Else
				OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
			EndIf;
		Else
			OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
		EndIf;
	EndIf;
	
	Return OptionOfDataReceivingFromRegisters;
	
EndFunction

Function HeadersForOptionGettingDataFromRegisters(OptionOfDataReceivingFromRegisters) Export
	
	If OptionOfDataReceivingFromRegisters = "GoodsReadyForReceipt" Then
		ButtonTitle            = NStr("vi = 'Cần tạo tiếp nhận';
										|ru = 'К оформлению поступления';
										|en = 'To register receipt'; fa = 'برای ثبت دریافت';
										|it = 'Arrivi da formalizzare';
										|pl = 'Do rejestracji wpływy';
										|tr = 'Tahsilat düzenlenmesi için'");
		FreeBalanceHeader = NStr("vi = 'Số dư theo lệnh, %UnitOfMeasure%';
								|ru = 'Остаток по распоряжению, %UnitOfMeasure%';
								|en = 'Reference balance, %UnitOfMeasure%'; fa = 'Reference balance, %UnitOfMeasure%';
								|it = 'Saldo su disposizione, %UnitOfMeasure%';
								|pl = 'Reszta wg zamówienia, %UnitOfMeasure%';
								|tr = 'Sipariş bakiyesi, %UnitOfMeasure%'");
	ElsIf OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesFromRemainder"
		Or OptionOfDataReceivingFromRegisters = "OrderSeriesFromRemainder" Then
		ButtonTitle            = NStr("vi = 'Số dư tự do';
										|ru = 'Свободные остатки';
										|en = 'Available inventory'; fa = 'موجودی در دسترس';
										|it = 'Saldi liberi';
										|pl = 'Wolne pozostałości';
										|tr = 'Mevcut stok'");
		FreeBalanceHeader = NStr("vi = 'Số dư tự do, %UnitOfMeasure%';
								|ru = 'Свободный остаток, %UnitOfMeasure%';
								|en = 'Available inventory, %UnitOfMeasure%'; fa = 'Available inventory, %UnitOfMeasure%';
								|it = 'Saldo libero, %UnitOfMeasure%';
								|pl = 'Wolny ostatek, %UnitOfMeasure%';
								|tr = 'Serbest bakiye, %UnitOfMeasure%'");
	ElsIf OptionOfDataReceivingFromRegisters = "InvoiceOfSeriesFromOrder" Then
		ButtonTitle = NStr("vi = 'Số dư theo đơn hàng';
							|ru = 'Остатки по заказу';
							|en = 'Order balance'; fa = 'Order balance';
							|it = 'Saldi su ordine';
							|pl = 'Pozostałość dla zlecenia';
							|tr = 'Sipariş bakiyeleri'");
		FreeBalanceHeader = NStr("vi = 'Số dư theo đơn hàng, %UnitOfMeasure%';
								|ru = 'Остаток по заказу, %UnitOfMeasure%';
								|en = 'Order balance, %UnitOfMeasure%'; fa = 'Order balance, %UnitOfMeasure%';
								|it = 'Saldo su ordine, %UnitOfMeasure%';
								|pl = 'Pozostałość dla zlecenia, %UnitOfMeasure%';
								|tr = 'Sipariş bakiyesi, %UnitOfMeasure%'");
	ElsIf OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesOnBalancesWithKeeper" Then
		ButtonTitle            = NStr("vi = 'Đã chuyển cho khách';
										|ru = 'Переданные клиенту';
										|en = 'Passed to the customer'; fa = 'Passed to the customer';
										|it = 'Passed to the customer';
										|pl = 'Passed to the customer';
										|tr = 'Müşteriye transfer edilenler'");
		FreeBalanceHeader = NStr("vi = 'Đã chuyển cho khách, %UnitOfMeasure%';
								|ru = 'Переданные клиенту, %UnitOfMeasure%';
								|en = 'Passed to the customer, %UnitOfMeasure%'; fa = 'Passed to the customer, %UnitOfMeasure%';
								|it = 'Passed to the customer, %UnitOfMeasure%';
								|pl = 'Passed to the customer, %UnitOfMeasure%';
								|tr = 'Müşteriye transfer edilenler, %UnitOfMeasure%'");
	ElsIf OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesOnBalancesWithCommissionAgent" Then
		ButtonTitle            = NStr("vi = 'Của người nhận ký gửi';
										|ru = 'У комиссионера';
										|en = 'At consignee'; fa = 'At consignee';
										|it = 'Presso il commissionario';
										|pl = 'U komisanta';
										|tr = 'Konsinyede'");
		FreeBalanceHeader = NStr("vi = 'Của người nhận ký gửi, %UnitOfMeasure%';
								|ru = 'У комиссионера, %UnitOfMeasure%';
								|en = 'At consignee, %UnitOfMeasure%'; fa = 'At consignee, %UnitOfMeasure%';
								|it = 'Presso il commissionario, %UnitOfMeasure%';
								|pl = 'U komisanta, %UnitOfMeasure%';
								|tr = 'Konsinyede, %UnitOfMeasure%'");
	ElsIf OptionOfDataReceivingFromRegisters = "OrderIsSeriesInvoiceForCommitteeSBalances" Then
		ButtonTitle            = NStr("vi = 'Của người đặt hàng';
										|ru = 'У комитента';
										|en = 'At consignor'; fa = 'At consignor';
										|it = 'У комитента';
										|pl = 'At consignor';
										|tr = 'Göndericinin'");
		FreeBalanceHeader = NStr("vi = 'Của người đặt hàng, %UnitOfMeasure%';
								|ru = 'У комитента, %UnitOfMeasure%';
								|en = 'At consignor, %UnitOfMeasure%'; fa = 'At consignor, %UnitOfMeasure%';
								|it = 'У комитента, %UnitOfMeasure%';
								|pl = 'At consignor, %UnitOfMeasure%';
								|tr = 'Göndericinin, %UnitOfMeasure%'");
	ElsIf OptionOfDataReceivingFromRegisters = "OrderSeriesFromInvoice" Then
		ButtonTitle = NStr("vi = 'Số dư theo lệnh';
							|ru = 'Остатки по распоряжению';
							|en = 'Remaining quantity acc. to reference'; fa = 'Remaining quantity acc. to reference';
							|it = 'Saldi su disposizione';
							|pl = 'Reszta wg zamówienia';
							|tr = 'Sipariş bakiyeleri'");
		FreeBalanceHeader = NStr("vi = 'Số dư theo lệnh, %UnitOfMeasure%';
								|ru = 'Остаток по распоряжению, %UnitOfMeasure%';
								|en = 'Reference balance, %UnitOfMeasure%'; fa = 'Reference balance, %UnitOfMeasure%';
								|it = 'Saldo su disposizione, %UnitOfMeasure%';
								|pl = 'Reszta wg zamówienia, %UnitOfMeasure%';
								|tr = 'Sipariş bakiyesi, %UnitOfMeasure%'");
	ElsIf OptionOfDataReceivingFromRegisters = "AllSeriesProducts" Then
		ButtonTitle = "";
		FreeBalanceHeader = "";
	ElsIf OptionOfDataReceivingFromRegisters = "ConsignmentNoteOfSeriesFromRemainderOfTMTSVOperation" Then
		ButtonTitle = NStr("vi = 'Đang sử dụng';
							|ru = 'В эксплуатации';
							|en = 'In operation'; fa = 'در حال بهره‌برداری';
							|it = 'In esercizio';
							|pl = 'W eksploatacji';
							|tr = 'Kullanımda'");
		FreeBalanceHeader = NStr("vi = 'Đang sử dụng, %UnitOfMeasure%';
								|ru = 'В эксплуатации, %UnitOfMeasure%';
								|en = 'In operation, %UnitOfMeasure%'; fa = 'In operation, %UnitOfMeasure%';
								|it = 'In lavorazione, %UnitOfMeasure%';
								|pl = 'W eksploatacji, %UnitOfMeasure%';
								|tr = 'Kullanımda, %UnitOfMeasure%'");
	EndIf;

	Result = New Structure;
	Result.Insert("ButtonTitle", ButtonTitle);
	Result.Insert("FreeBalanceHeader", FreeBalanceHeader);
	
	Return Result;
	
EndFunction

Function OrderOnFormParameters(FormParameters) Export
	
	If FormParameters.FieldValuesToIdentifyReferences.Count() > 0 Then
		ObjectManager = Common.ObjectManagerByFullName(FormParameters.SeriesSpecificationParameters.FullObjectName);
		ReferenceOrder = ObjectManager.OrderToPerformWarehouseOperation(FormParameters.FieldValuesToIdentifyReferences);
	Else
		ReferenceOrder = Undefined;
	EndIf;
	
	Return ReferenceOrder;
	
EndFunction

Function RequestTextDetailsOfSeries(TableName, SeriesUseSettings, ForDimensionFields = False, TakeValuesOfDetailsFromLink = True) Export
	
	If TakeValuesOfDetailsFromLink Then
		PropsSelectionTemplate = "	TableOfSeries.Series.%AttributeName% AS %AttributeName%";
	Else
		PropsSelectionTemplate = "	TableOfSeries.%AttributeName% AS %AttributeName%";
	EndIf;
	
	ArrayOfTexts = New Array;
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		
		If ForDimensionFields Then
			AttributeText = StrReplace(PropsSelectionTemplate, "AS %AttributeName%", "");
		Else
			AttributeText = PropsSelectionTemplate;
		EndIf;
		
		AttributeText = StrReplace(AttributeText, "%AttributeName%", LongDesc.AttributeName);
		
		ArrayOfTexts.Add(AttributeText);
		
		If LongDesc.AttributeName = "RFIDTID" Then
			
			If TakeValuesOfDetailsFromLink Then
				AttributeText = "	TableOfSeries.Series.RFIDTID <> """" AS RFIDTIDFilledIn";
			Else
				AttributeText = "	TableOfSeries.RFIDTID <> """" AS RFIDTIDFilledIn";
			EndIf;
			
			If ForDimensionFields Then
				AttributeText = StrReplace(AttributeText, "AS RFIDTIDFilledIn", "");
			EndIf;
			ArrayOfTexts.Add(AttributeText);
			
			If TakeValuesOfDetailsFromLink Then
				AttributeText = 
				"	CASE
				|		WHEN TableOfSeries.Series.RFIDTID <> """"
				|			THEN 2
				|		ELSE 0
				|	END AS RFIDOperationStatus"; 
			Else
				AttributeText = 
				"	CASE
				|		WHEN TableOfSeries.RFIDTID <> """"
				|			THEN 2
				|		ELSE 0
				|	END AS RFIDOperationStatus"; 
			EndIf;
			
			If ForDimensionFields Then
				AttributeText = StrReplace(AttributeText, "AS RFIDOperationStatus", "");
			EndIf;
			ArrayOfTexts.Add(AttributeText);
		EndIf;
		
	EndDo;
	
	RequestTextDetailsOfSeries = StrConcat(ArrayOfTexts, "," + Chars.LF);
	
	RequestTextDetailsOfSeries = StrReplace(RequestTextDetailsOfSeries, "TableOfSeries", TableName);
	
	Return RequestTextDetailsOfSeries;
	
EndFunction

Function NamesOfSeriesElements(AttributeName) Export
	
	ReturnStructure = New Structure("SetOfSeries, RemainingSeries");
	
	If AttributeName = "Number" Then
		ReturnStructure.SetOfSeries = "SetOfSeriesNumber";
		ReturnStructure.RemainingSeries = "RemainingSeriesNumber";
	ElsIf AttributeName = "ProductionDate" Then
		ReturnStructure.SetOfSeries = "SetOfSeriesProductionDate";
		ReturnStructure.RemainingSeries = "RemainingSeriesProductionDate";
	ElsIf AttributeName = "ValidUntil_" Then
		ReturnStructure.SetOfSeries = "SetOfSeriesValidUntil_";
		ReturnStructure.RemainingSeries = "RemainingSeriesValidUntil_";
	ElsIf Upper(AttributeName) = Upper("NumberOfSPMSControlIdentificationMark") Then
		ReturnStructure.SetOfSeries = "SetOfSeriesNumberOfSPMSControlIdentificationMark";
		ReturnStructure.RemainingSeries = "RemainingSeriesNumberOfSPMSControlIdentificationMark";
	ElsIf AttributeName = "ManufacturerUSAIS" Then
		ReturnStructure.SetOfSeries = "SetOfSeriesManufacturerUSAIS";
		ReturnStructure.RemainingSeries = "RemainingSeriesManufacturerUSAIS";
	ElsIf AttributeName = "Certificate2USAIS" Then
		ReturnStructure.SetOfSeries = "SetOfSeriesCertificate2USAIS";
		ReturnStructure.RemainingSeries = "RemainingSeriesCertificate2USAIS";
	ElsIf AttributeName = "ManufacturerVetIS" Then
		ReturnStructure.SetOfSeries = "SetOfSeriesManufacturerVetIS";
		ReturnStructure.RemainingSeries = "RemainingSeriesManufacturerVetIS";
	ElsIf AttributeName = "WarehouseBookRecordVetIS" Then
		ReturnStructure.SetOfSeries = "SetOfSeriesWarehouseBookRecordVetIS";
		ReturnStructure.RemainingSeries = "RemainingSeriesWarehouseBookRecordVetIS";
	ElsIf AttributeName = "LotIDVetIS" Then
		ReturnStructure.SetOfSeries = "SetOfSeriesLotIDVetIS";
		ReturnStructure.RemainingSeries = "RemainingSeriesLotIDVetIS";
	ElsIf AttributeName = "MaximumRetailPriceMOTP" Then
		ReturnStructure.SetOfSeries = "SetOfSeriesMaximumRetailPriceMOTP";
		ReturnStructure.RemainingSeries = "RemainingSeriesMaximumRetailPriceMOTP";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

#EndRegion

#EndIf
