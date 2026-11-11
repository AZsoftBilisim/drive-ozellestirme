#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Internal

Function AccessStructure() Export
	
	OptionOfSeparationInMovement = Constants.OptionOfGoodslAssignmentInTransfer.Get();
	OptionOfSeparationDuringTransfer  = Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Get();
	MoveOrderIsAvailable = GetFunctionalOption("UseTransferOrders")
		And OptionOfSeparationInMovement = Enums.OptionsOfGoodslAssignmentInTransfer.AssignmentRecipient
		And AccessRight("Insert", Metadata.Documents.TransferOrder);
		
	OrderingMaterialsIsAvailable = False;
	OrderingMaterialsIsAvailable = GetFunctionalOption("UseProductionManagement2_2")
		And OptionOfSeparationDuringTransfer = Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.AssignmentRecipient
		And AccessRight("Insert", Metadata.Documents.OrderOfMaterialsForProduction);
	MovingIsAvailable = GetFunctionalOption("UseGoodsTransfer")
		And AccessRight("Insert", Metadata.Documents.InventoryTransfer);
		
	TransferOfMaterialsIsAvailable = False;
	TransferOfMaterialsIsAvailable = GetFunctionalOption("UseProductionManagement2_2")
		And AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials);
	AccessStructure = New Structure;
	AccessStructure.Insert("MoveOrderIsAvailable", MoveOrderIsAvailable);
	AccessStructure.Insert("OrderingMaterialsIsAvailable",    OrderingMaterialsIsAvailable);
	AccessStructure.Insert("MovingIsAvailable",        MovingIsAvailable);
	AccessStructure.Insert("TransferOfMaterialsIsAvailable", TransferOfMaterialsIsAvailable);
	
	Return AccessStructure;
	
EndFunction

Function StructureFillingData() Export
	
	StructureFillingData = New Structure();
	
	StructureFillingData.Insert("SourceWarehouse",      Undefined);
	StructureFillingData.Insert("DestinationWarehouse",       Undefined);
	StructureFillingData.Insert("Purpose",            Undefined);
	StructureFillingData.Insert("DateOfShipment",          Undefined);
	StructureFillingData.Insert("DateOfNextShipment", Undefined);
	StructureFillingData.Insert("DemandsBeforeDate",     Undefined);
	StructureFillingData.Insert("RegistrationOption",     Undefined);
	
	Return StructureFillingData;
	
EndFunction

Procedure MovingItemsToTable(Parameters, StorageAddress) Export
	
	Goods = Parameters.Goods.CopyColumns(); // ValueTable - 
	Goods.Columns.Add("DetailedRecords", New TypeDescription("ValueTable"));
	Goods.Columns.Add("SearchStringNumber", New TypeDescription("Number"));
	
	DataProcessorObject = DataProcessors.TransferOfAssignedGoods.Create();
	Fill(Parameters.FillingData, Goods, Parameters.ThisIsDistributionOfResiduals);
	GoodsFillInServiceDetails(Goods);
	WarehouseCart = Parameters.WarehouseCart.CopyColumns();
	FillWarehouseBasket(Goods, WarehouseCart);
	
	FillingResult = New Structure("Goods, WarehouseCart", Goods, WarehouseCart);
	PutToTempStorage(FillingResult, StorageAddress);
	
EndProcedure

// Parameters:
//  ShipmentStart - Date - Date of commencement of the shipment.
//  UnloadedTable - ValueTable - A table containing data for processing documents.
//  RegistrationOption - EnumRef.OptionsOfRegisteringTransferDocuments - Option for processing documents.
// 
// Returns:
//  Structure - structure of created documents and errors.
Function IssueDocuments(ShipmentStart, UnloadedTable, RegistrationOption) Export
	
	ErrorsMessages = New Array();
	CreatedDocuments = New Array();
	
	UnloadedTable.Columns.Add("ShipmentStart", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	UnloadedTable.Columns.Add("ReceiptEnd", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	UnloadedTable.Columns.Add("SupplyOption");
	UnloadedTable.Columns.Add("WithAssignment");
	
	SupplyOption = Enums.SupplyOptions.ToSupply;
	DurationOfDay = 3600 * 24;
	For Each TableRow In UnloadedTable Do
		
		TableRow.SupplyOption = SupplyOption;
		TableRow.WithAssignment = True;
		TableRow.ShipmentStart = ShipmentStart;
		TableRow.ReceiptEnd = ShipmentStart + DurationOfDay * TableRow.TransferDurationDays;
		
	EndDo;
	
	KeyFields = "SourceWarehouse,DestinationWarehouse,LineOfBusiness";
	UnloadedTable.Sort(KeyFields, New CompareValues);
	
	PartitioningResult = SupplyServer.SplitTableByKeyValue(UnloadedTable, KeyFields, KeyFields);
	
	AccessStructure = DataProcessors.TransferOfAssignedGoods.AccessStructure();
	
	Storerooms = New Map();
	Storerooms = Common.ObjectsAttributeValue(UnloadedTable.UnloadColumn("DestinationWarehouse"), "ShopFloorStockroom");
	If RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.TransferOrder Then
		
		For Each Item In PartitioningResult Do
			
			If AccessStructure.OrderingMaterialsIsAvailable And Storerooms.Get(Item.Key.DestinationWarehouse) = True Then
				DocumentFillingData = New Structure("Warehouse,ShopFloorStockroom,LineOfBusiness,Goods");
				DocumentFillingData.Warehouse                   = Item.Key.SourceWarehouse;
				DocumentFillingData.ShopFloorStockroom         = Item.Key.DestinationWarehouse;
				DocumentFillingData.LineOfBusiness = Item.Key.LineOfBusiness;
				DocumentFillingData.Goods = Item.Table;
				
				DocumentObject = DataProcessors.DemandFulfillment.FillInAndHoldDocument(
					Documents.OrderOfMaterialsForProduction,
					DocumentFillingData,
					Enums.StatusesOfOrdersForMaterialsForProduction.ForCompletion,
					ErrorsMessages);
			Else
				
				DocumentFillingData = New Structure("SourceWarehouse,DestinationWarehouse,LineOfBusiness,Goods");
				FillPropertyValues(DocumentFillingData, Item.Key);
				DocumentFillingData.Goods = Item.Table;
				
				DocumentObject = DataProcessors.DemandFulfillment.FillInAndHoldDocument(
					Documents.TransferOrder,
					DocumentFillingData,
					Enums.InternalOrderStatuses.ForCompletion,
					ErrorsMessages);
				
			EndIf;
			
			CreatedDocuments.Add(DocumentObject.Ref);
			
		EndDo;
		
	ElsIf RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer Then
		
		For Each Item In PartitioningResult Do
			
			If AccessStructure.TransferOfMaterialsIsAvailable And Storerooms.Get(Item.Key.DestinationWarehouse) = True Then
				HeaderAttributes = New Structure;
				HeaderAttributes.Insert("BusinessOperation",   Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
				HeaderAttributes.Insert("Sender",             Item.Key.SourceWarehouse);
				HeaderAttributes.Insert("Recipient",              Item.Key.DestinationWarehouse);
				HeaderAttributes.Insert("LineOfBusiness", Item.Key.LineOfBusiness);
				HeaderAttributes.Insert("Date",                    CurrentSessionDate());
				
				DocumentFillingData = New Structure("HeaderAttributes, Goods", HeaderAttributes, Item.Table);
				
				DocumentObject = DataProcessors.DemandFulfillment.FillInAndHoldDocument(
					Documents.MovementOfProductsAndMaterials,
					DocumentFillingData,
					Enums.StatusesOfProductsAndMaterialMovement.Shipped,
					ErrorsMessages);
			Else
				
				DocumentFillingData = New Structure("SourceWarehouse,DestinationWarehouse,LineOfBusiness,Goods");
				FillPropertyValues(DocumentFillingData, Item.Key);
				DocumentFillingData.Goods = Item.Table;
				
				DocumentObject = DataProcessors.DemandFulfillment.FillInAndHoldDocument(
					Documents.InventoryTransfer,
					DocumentFillingData,
					Enums.GoodsTransferStatuses.Shipped,
					ErrorsMessages);
				
			EndIf;
			
			CreatedDocuments.Add(DocumentObject.Ref);
			
		EndDo;
		
	EndIf;
	
	ExecutionResult = New Structure("Documents, Messages", CreatedDocuments, ErrorsMessages);
	Return ExecutionResult;
	
EndFunction

#EndRegion

#Region OtherItems

Procedure Fill(FillingData, Goods, ThisIsDistributionOfResiduals)
	
	SourceWarehouse      = FillingData.SourceWarehouse;
	DestinationWarehouse       = FillingData.DestinationWarehouse;
	Purpose            = FillingData.Purpose;
	DateOfShipment          = FillingData.DateOfShipment;
	DateOfNextShipment = FillingData.DateOfNextShipment;
	DemandsBeforeDate     = FillingData.DemandsBeforeDate;
	RegistrationOption     = FillingData.RegistrationOption;
	
	Filters = New Structure();
	If ValueIsFilled(SourceWarehouse) Then
		Filters.Insert("SourceWarehouse", SourceWarehouse);
	EndIf;
	
	If ValueIsFilled(DestinationWarehouse) Then
		Filters.Insert("DestinationWarehouse", DestinationWarehouse);
	EndIf;
	
	If ValueIsFilled(Purpose) Then
		Filters.Insert("Purpose", Purpose);
	EndIf;
	
	FilterShopFloorStockroom = FilterShopFloorStockroom(RegistrationOption);
	
	If FilterShopFloorStockroom <> Undefined Then
		Filters.Insert("FilterShopFloorStockroom", FilterShopFloorStockroom);
	EndIf;
	
	GoodsTable = Goods(DateOfShipment, DateOfNextShipment, DemandsBeforeDate, Filters, ThisIsDistributionOfResiduals);
	
	GoodsTable.Sort(
		"Products,
		|Characteristic,
		|Purpose,
		|SourceWarehouse,
		|DestinationWarehouse");
	
	MaxIndex_ = GoodsTable.Count() - 1;
	IndexOf = 0;
	ThereAreRecords = IndexOf <= MaxIndex_;
	RowKey = New Structure("Products,Characteristic,Purpose");
	EmptyWarehouse = Catalogs.Warehouses.EmptyRef();
	
	LineNumber = 1;
	While ThereAreRecords Do
	
		LineProducts_ = GoodsTable[IndexOf];
		FillPropertyValues(RowKey, LineProducts_);
		
		ChangedRecord = False;
		
		NewRow = Goods.Add();
		NewRow.SearchStringNumber = LineNumber;
		LineNumber = LineNumber + 1;
		
		FillPropertyValues(NewRow, RowKey);
		DetailedRecords = NewRow.DetailedRecords;
		FillInColumnsOfDetailedRecordsTable(DetailedRecords);
		
		NewRow.SeveralDemandDates = False;
		MultipleSenderWarehouses = False;
		MultipleRecipientWarehouses  = False;
		
		// Cycle by combination of nomenclature\characteristic\purpose.
		While Not ChangedRecord Do
			
			LineProducts_ = GoodsTable[IndexOf];
			
			If LineProducts_.Demand > 0 Or LineProducts_.Available > 0 Then
				
				// Filling in a detailed record.
				ForTransfer = Min(LineProducts_.Available, LineProducts_.Demand);
				If ForTransfer > 0 Then
					
					DetailRecord = DetailedRecords.Add();
					FillPropertyValues(DetailRecord, LineProducts_,
						"Period,
						|DemandDate,
						|Priority,
						|PriorityOfOrderingProps,
						|Period,
						|DemandDate");
					DetailRecord.ForTransfer = ForTransfer;
					
					If ThisIsDistributionOfResiduals Then
						DetailRecord.Warehouse = LineProducts_.DestinationWarehouse;
						DetailRecord.WarehouseName = LineProducts_.WarehouseRecipientName;
					Else
						DetailRecord.Warehouse = LineProducts_.SourceWarehouse;
						DetailRecord.WarehouseName = LineProducts_.WarehouseSenderName;
					EndIf;
					
				EndIf;
				
				// Filling in the fields of the main record (the Warehouse Sender, Warehouse Recipient, data needs fields).
				If ThisIsDistributionOfResiduals
						And LineProducts_.DemandDate <> NewRow.DemandDate
						And NewRow.DemandDate <> '00010101'
						And LineProducts_.DemandDate <> '00010101' Then
					
					NewRow.SeveralDemandDates = True;
					
				EndIf;
				
				If LineProducts_.SourceWarehouse <> NewRow.SourceWarehouse
						And Not NewRow.SourceWarehouse.IsEmpty()
						And Not LineProducts_.SourceWarehouse.IsEmpty() Then
					
					MultipleSenderWarehouses = True;
					NewRow.SourceWarehouse = EmptyWarehouse;
					
				EndIf;
				
				If LineProducts_.DestinationWarehouse <> NewRow.DestinationWarehouse
						And Not NewRow.DestinationWarehouse.IsEmpty()
						And Not LineProducts_.DestinationWarehouse.IsEmpty() Then
					
					MultipleRecipientWarehouses = True;
					NewRow.DestinationWarehouse = EmptyWarehouse;
					
				EndIf;
				
				If Not ThisIsDistributionOfResiduals Then
					
					If NewRow.DemandDate = '00010101' Or LineProducts_.DemandDate < NewRow.DemandDate Then
						NewRow.DemandDate = LineProducts_.DemandDate;
					EndIf;
					
				ElsIf NewRow.SeveralDemandDates Then
					NewRow.DemandDate = '00010101';
				ElsIf ValueIsFilled(LineProducts_.DemandDate) Then
					NewRow.DemandDate = LineProducts_.DemandDate;
				EndIf;
				
				If Not MultipleSenderWarehouses And ValueIsFilled(LineProducts_.SourceWarehouse) Then
					NewRow.SourceWarehouse = LineProducts_.SourceWarehouse;
				EndIf;
				
				If Not MultipleRecipientWarehouses And ValueIsFilled(LineProducts_.DestinationWarehouse) Then
					NewRow.DestinationWarehouse = LineProducts_.DestinationWarehouse;
				EndIf;
				
				// Filling in the fields of the main record (fields Need, Available, Quantity, quantity of packages, Mark).
				NewRow.Demand = NewRow.Demand + LineProducts_.Demand;
				NewRow.Available    = NewRow.Available    + LineProducts_.Available;
				
				If ForTransfer > 0 Then
					NewRow.Count = NewRow.Count  + ForTransfer;
					NewRow.NumberOfPackages = NewRow.Count;
					NewRow.Mark = True;
				EndIf;
			
				// Filling in the fields of the main record (the fields are provided by the transfer, the duration of the transfer, the order is received).
				NewRow.SuppliedByTransfer = NewRow.SuppliedByTransfer Or LineProducts_.SuppliedByTransfer;
				NewRow.TransferDurationDays    = Max(NewRow.TransferDurationDays, LineProducts_.TransferDurationDays);
				NewRow.WillBeDeliveredOnTime              = Min(NewRow.WillBeDeliveredOnTime, LineProducts_.WillBeDeliveredOnTime);
				
			EndIf;
			
			// Go to the next record.
			IndexOf = IndexOf + 1;
			ThereAreRecords = IndexOf <= MaxIndex_;
			
			ChangedRecord = Not ThereAreRecords Or SupplyServer.KeyChanged(RowKey, GoodsTable[IndexOf]);
			
		EndDo;
		
		OrderColumns = OrderColumns(ThisIsDistributionOfResiduals, "WarehouseName,Warehouse");
		DetailedRecords.GroupBy(OrderColumns, "ForTransfer");
		DetailedRecords.Sort(OrderColumns);
		
	EndDo;
	
EndProcedure

Function OrderColumns(ThisIsDistributionOfResiduals, WarehouseFields)
		
		If ThisIsDistributionOfResiduals Then
			OrderColumns = StrReplace(
				"PriorityOfOrderingProps,
				|Priority,
				|Period,
				|DemandDate,
				|WarehouseFields",
				"WarehouseFields",
				WarehouseFields);
		Else
			OrderColumns = WarehouseFields;
		EndIf;
		
	Return OrderColumns;
	
EndFunction

Function FilterShopFloorStockroom(RegistrationOption)
	
	FilterShopFloorStockroom = Undefined;
	AccessStructure = AccessStructure();
	If RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.TransferOrder
			And Not AccessStructure.MoveOrderIsAvailable Then
			
			FilterShopFloorStockroom = True;
			
	ElsIf RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.TransferOrder
			And Not AccessStructure.OrderingMaterialsIsAvailable Then
			
			FilterShopFloorStockroom = False;
			
	ElsIf RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer
			And Not AccessStructure.MovingIsAvailable Then
			
			FilterShopFloorStockroom = True;
			
	ElsIf RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer
			And Not AccessStructure.TransferOfMaterialsIsAvailable Then
			
			FilterShopFloorStockroom = False;
			
	EndIf;
	
	Return FilterShopFloorStockroom;
	
EndFunction

Function Goods(DateOfShipment, DateOfNextShipment, DemandsBeforeDate, Filters, ThisIsDistributionOfResiduals)
	
	ResultStructure1 = NeedsAndAvailableBalances(Filters);
	Demands      = ResultStructure1.Demands;
	Available2Balance = ResultStructure1.Available2Balance;
	
	Query = New Query();
	Query.SetParameter("TableRecipients", Demands);
	Query.SetParameter("SendersTable",Available2Balance);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("DateOfShipment",      DateOfShipment);
	Query.SetParameter("DateOfNextShipment", DateOfNextShipment);
	Query.SetParameter("DemandsBeforeDate", DemandsBeforeDate);
	Query.SetParameter("ThereIsSelectionByDateOfNextShipment", ValueIsFilled(DateOfNextShipment) And ThisIsDistributionOfResiduals);
	Query.SetParameter("ThereIsSelectionByNeedBeforeDate", ValueIsFilled(DemandsBeforeDate) And Not ThisIsDistributionOfResiduals);
	Query.SetParameter("ThisIsDistributionOfResiduals", ThisIsDistributionOfResiduals);
	
	Query.Text =
		// 4.1) Loading of the table of available balances in the sender warehouse, with the availability date no later than the date "To be shipped before the date".
		"SELECT
		|	SendersTable.Products    AS Products,
		|	SendersTable.Characteristic  AS Characteristic,
		|	SendersTable.Warehouse           AS Warehouse,
		|	SendersTable.Purpose      AS Purpose,
		|	SendersTable.AvailabilityDate AS AvailabilityDate,
		|	SendersTable.Count      AS Count
		|INTO TTSenders
		|FROM
		|	&SendersTable AS SendersTable
		|WHERE
		|	CASE WHEN &DateOfShipment = &CurrentDayStart THEN
		|				SendersTable.AvailabilityDate = DATETIME(1, 1, 1)
		|			ELSE
		|				SendersTable.AvailabilityDate <= &DateOfShipment
		|		END
		|;
		|
		|//////////////////////////////////////////////////////
		|SELECT
		|	SendersTable.Products    AS Products,
		|	SendersTable.Characteristic  AS Characteristic,
		|	SendersTable.Purpose      AS Purpose,
		|	MAX(SendersTable.Warehouse) AS Warehouse
		|INTO TTSendersProductList
		|FROM
		|	TTSenders AS SendersTable
		|GROUP BY
		|	SendersTable.Products, SendersTable.Characteristic, SendersTable.Purpose
		|INDEX BY
		|	Products, Characteristic, Purpose
		|;
		|
		|//////////////////////////////////////////////////////
		// 4.2) Loading the needs table at the receiving warehouse.
		|SELECT
		|	TableRecipients.Products   AS Products,
		|	TableRecipients.Characteristic AS Characteristic,
		|	TableRecipients.Warehouse          AS Warehouse,
		|	TableRecipients.Purpose     AS Purpose,
		|	TableRecipients.Priority      AS Priority,
		|	TableRecipients.PriorityOfOrderingProps AS PriorityOfOrderingProps,
		|	TableRecipients.DateOfShipment   AS DateOfShipment,
		|	TableRecipients.Count     AS Count
		|INTO TTRecipients
		|FROM
		|	&TableRecipients AS TableRecipients
		|INDEX BY
		|	Products, Characteristic, Purpose
		|;
		|
		|//////////////////////////////////////////////////////
		|";
		
	// 4.3) Definition of the main method of provision.
	TextOfCalculationOfProvisionMethod =
		Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False) +
		"SELECT DISTINCT
		|	Goods.Products              AS Products,
		|	Goods.Characteristic            AS Characteristic,
		|	Goods.Warehouse                     AS Warehouse,
		|	
		|	MainWayToEnsure.SupplyType = VALUE(Enum.SupplyTypes.Move)               AS SuppliedByTransfer,
		|	ISNULL(MainWayToEnsure.ProductionDurationDays, 0)                                                    AS TransferDurationDays,
		|	MainWayToEnsure.SourceOfDemandSupply REFS Catalog.Warehouses
		|		AND MainWayToEnsure.SourceOfDemandSupply <> VALUE(Catalog.Warehouses.EmptyRef) AS WarehouseSenderIsKnown,
		|	MainWayToEnsure.SourceOfDemandSupply                                                   AS SourceWarehouse
		|	
		|	
		|INTO TTWaysToEnsure
		|FROM
		|	TTRecipients AS Goods
		|		
		|		LEFT JOIN Catalog.ProcurementStrategies AS MainWayToEnsure
		|		ON &MainSupplyMethodSubstitution
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|";
		
	Query.Text = Query.Text
		+ InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(TextOfCalculationOfProvisionMethod,
			"MainSupplyMethodSubstitution",
			"Goods.Products, Goods.Characteristic, Goods.Warehouse");
	
	Query.Text = Query.Text +
		// The needs of the recipient.
		"SELECT
		|	TableRecipients.Products      AS Products,
		|	TableRecipients.Characteristic    AS Characteristic,
		|	TableRecipients.Warehouse             AS DestinationWarehouse,
		|	TableRecipients.Warehouse.Description AS WarehouseRecipientName,
		|	TableRecipients.Purpose        AS Purpose,
		|	ISNULL(TableRecipients.Purpose.LineOfBusiness,
		|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
		|	CASE
		|		WHEN OrderingByDocumentDate.Value IS NULL
		|			THEN TableRecipients.DateOfShipment
		|		ELSE UNDEFINED
		|	END AS DemandDate,
		|	CASE
		|		WHEN OrderingByDocumentDate.Value IS NULL
		|			THEN DATEADD(TableRecipients.DateOfShipment, DAY, -SupplyMethods.TransferDurationDays)
		|		ELSE UNDEFINED
		|	END AS Period,
		|	TableRecipients.Priority AS Priority,
		|	TableRecipients.PriorityOfOrderingProps AS PriorityOfOrderingProps,
		|	TableRecipients.DateOfShipment >= DATEADD(&DateOfShipment, DAY,SupplyMethods.TransferDurationDays) AS WillBeDeliveredOnTime,
		|	
		|	SupplyMethods.SuppliedByTransfer AS SuppliedByTransfer,
		|	SupplyMethods.TransferDurationDays AS TransferDurationDays,
		|	SupplyMethods.WarehouseSenderIsKnown AS WarehouseSenderIsKnown,
		|	SupplyMethods.SourceWarehouse AS SourceWarehouse,
		|	
		|	TableRecipients.Count AS Demand
		|	
		|FROM
		|	TTRecipients AS TableRecipients
		|		
		|		LEFT JOIN Constant.OptionOfOrderingDemandsByOrdersForSupply AS OrderingByDocumentDate
		|		ON OrderingByDocumentDate.Value = VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate)
		|		
		|		LEFT JOIN TTWaysToEnsure AS SupplyMethods
		|		ON SupplyMethods.Products   = TableRecipients.Products
		|		 AND SupplyMethods.Characteristic = TableRecipients.Characteristic
		|		 AND SupplyMethods.Warehouse          = TableRecipients.Warehouse
		|		
		|		LEFT JOIN TTSendersProductList AS TTSendersProductList
		|		ON TTSendersProductList.Products   = TableRecipients.Products
		|		 AND TTSendersProductList.Characteristic = TableRecipients.Characteristic
		|		 AND TTSendersProductList.Purpose     = TableRecipients.Purpose
		|		 AND (TTSendersProductList.Warehouse <> TableRecipients.Warehouse OR NOT &ThisIsDistributionOfResiduals)
		|WHERE
		|	(TableRecipients.DateOfShipment < DATEADD(&DateOfNextShipment, DAY, SupplyMethods.TransferDurationDays) OR NOT &ThereIsSelectionByDateOfNextShipment)
		|	AND (TableRecipients.DateOfShipment < &DemandsBeforeDate OR NOT &ThereIsSelectionByNeedBeforeDate)
		|	AND NOT TTSendersProductList.Products IS NULL
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	PriorityOfOrderingProps,
		|	Period,
		|	DemandDate,
		|	WarehouseRecipientName,
		|	DestinationWarehouse
		|;
		|///////////////////////////////////////////////////////
		// Sender's leftovers.
		|SELECT
		|	SendersTable.Products    AS Products,
		|	SendersTable.Characteristic  AS Characteristic,
		|	SendersTable.Warehouse           AS SourceWarehouse,
		|	MAX(SendersTable.Warehouse.Description) AS WarehouseSenderName,
		|	SendersTable.Purpose      AS Purpose,
		|	MAX(SendersTable.Count) AS Available,
		|	TRUE                             AS WillBeDeliveredOnTime
		|	
		|FROM
		|	TTSenders AS SendersTable
		|		
		|		LEFT JOIN TTRecipients AS TableRecipients
		|		ON TableRecipients.Products   = SendersTable.Products
		|		 AND TableRecipients.Characteristic = SendersTable.Characteristic
		|		 AND TableRecipients.Purpose     = SendersTable.Purpose
		|		 AND (TableRecipients.Warehouse <> SendersTable.Warehouse OR &ThisIsDistributionOfResiduals)
		|	
		|		LEFT JOIN TTWaysToEnsure AS SupplyMethods
		|		ON SupplyMethods.Products   = TableRecipients.Products
		|		 AND SupplyMethods.Characteristic = TableRecipients.Characteristic
		|		 AND SupplyMethods.Warehouse          = TableRecipients.Warehouse
		|	
		|WHERE
		|	NOT TableRecipients.Products IS NULL
		|	AND (TableRecipients.DateOfShipment < DATEADD(&DateOfNextShipment, DAY, SupplyMethods.TransferDurationDays) OR NOT &ThereIsSelectionByDateOfNextShipment)
		|	AND (TableRecipients.DateOfShipment < &DemandsBeforeDate OR NOT &ThereIsSelectionByNeedBeforeDate)
		|GROUP BY
		|	SendersTable.Products,
		|	SendersTable.Characteristic,
		|	SendersTable.Warehouse,
		|	SendersTable.Purpose
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	WarehouseSenderName";
	
	ResultsPackage = Query.ExecuteBatch();
	TotalTables = ResultsPackage.Count();
	
	RecipientSNeeds = ResultsPackage[TotalTables - 2].Unload();
	SenderSBalances = ResultsPackage[TotalTables - 1].Unload();
	
	Result = New ValueTable();
	Result.Columns.Add("Products",               New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic",             New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("DestinationWarehouse",            New TypeDescription("CatalogRef.Warehouses"));
	Result.Columns.Add("Purpose",                 New TypeDescription("CatalogRef.Assignments"));
	Result.Columns.Add("LineOfBusiness",    New TypeDescription("CatalogRef.LinesOfBusiness"));
	Result.Columns.Add("SourceWarehouse",           New TypeDescription("CatalogRef.Warehouses"));
	Result.Columns.Add("Demand",                Common.TypeDescriptionNumber(15, 3));
	Result.Columns.Add("Available",                   Common.TypeDescriptionNumber(15, 3));
	Result.Columns.Add("TransferDurationDays",    Common.TypeDescriptionNumber(10, 0));
	Result.Columns.Add("SuppliedByTransfer", New TypeDescription("Boolean"));
	Result.Columns.Add("DemandDate",            TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	Result.Columns.Add("Period",                     TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	Result.Columns.Add("Priority",                  New TypeDescription("CatalogRef.Priorities"));
	Result.Columns.Add("PriorityOfOrderingProps", Common.TypeDescriptionNumber(5, 0, AllowedSign.Nonnegative));
	Result.Columns.Add("WillBeDeliveredOnTime",              New TypeDescription("Boolean"));
	Result.Columns.Add("WarehouseSenderName", New TypeDescription("String"));
	Result.Columns.Add("WarehouseRecipientName",  New TypeDescription("String"));
	
	FilterFields = "Products, Characteristic, Purpose";
	SenderSBalances.Indexes.Add(FilterFields);
	AllocateQuantity(Result, RecipientSNeeds, SenderSBalances, FilterFields);
	
	For Each String In RecipientSNeeds Do
		
		If String.Demand > 0 Then
			FillPropertyValues(Result.Add(), String);
		EndIf;
		
	EndDo;
	
	For Each String In SenderSBalances Do
		
		If String.Available > 0 Then
			FillPropertyValues(Result.Add(), String);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function NeedsAndAvailableBalances(Filters)
	
	Query = New Query();

	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|			AND &ProductsBalance
		|			AND &CharacteristicBalance
		|			AND &WarehouseBalance
		|			AND &PurposeBalance) AS Inventories
		|;
		|
		|////////////////////////////////////////////////
		|SELECT
		|	Calculation.Products AS Products,
		|	Calculation.Characteristic AS Characteristic,
		|	Calculation.Purpose AS Purpose,
		|	Calculation.Warehouse AS Warehouse,
		|	DATETIME(1, 1, 1) AS AvailabilityDate,
		|	Calculation.QuantityForShipAction AS Count
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|WHERE
		|	Calculation.QuantityForShipAction > 0
		|
		|UNION ALL
		|
		|SELECT
		|	InventoryAllocation.Products AS Products,
		|	InventoryAllocation.Characteristic AS Characteristic,
		|	InventoryAllocation.Purpose AS Purpose,
		|	InventoryAllocation.Warehouse AS Warehouse,
		|	InventoryAllocation.AvailabilityDate AS AvailabilityDate,
		|	SUM(InventoryAllocation.Count) AS Count
		|FROM
		|	InformationRegister.InventoryAllocation AS InventoryAllocation
		|WHERE
		|	InventoryAllocation.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|		AND InventoryAllocation.InventoryState IN(
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock))
		|		AND InventoryAllocation.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply),
		|			VALUE(Enum.DemandCharacteristics.Surplus))
		|		AND InventoryAllocation.Count > 0
		|		AND &ProductListOfInformation
		|		AND &CharacteristicsOfInformation
		|		AND &PurposeOfInformation
		|		AND &WarehouseInfo
		|GROUP BY
		|	InventoryAllocation.Products,
		|	InventoryAllocation.Characteristic,
		|	InventoryAllocation.Purpose,
		|	InventoryAllocation.Warehouse,
		|	InventoryAllocation.AvailabilityDate";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	If Filters.Property("Products") Then
		QueryText = StrReplace(QueryText, "&ProductsBalance", "Products = &Products");
		QueryText = StrReplace(QueryText, "&ProductListOfInformation", "InventoryAllocation.Products = &Products");
		Query.SetParameter("Products", Filters.Products);
	Else
		QueryText = StrReplace(QueryText, "&ProductsBalance", "TRUE");
		QueryText = StrReplace(QueryText, "&ProductListOfInformation", "TRUE");
	EndIf;
	
	If Filters.Property("Characteristic") Then
		QueryText = StrReplace(QueryText, "&CharacteristicBalance", "Characteristic = &Characteristic");
		QueryText = StrReplace(QueryText, "&CharacteristicsOfInformation", "InventoryAllocation.Characteristic = &Characteristic");
		Query.SetParameter("Characteristic", Filters.Characteristic);
	Else
		QueryText = StrReplace(QueryText, "&CharacteristicBalance", "TRUE");
		QueryText = StrReplace(QueryText, "&CharacteristicsOfInformation", "TRUE");
	EndIf;
	
	If Filters.Property("SourceWarehouse") Then
		QueryText = StrReplace(QueryText, "&WarehouseBalance", "Warehouse = &SourceWarehouse");
		QueryText = StrReplace(QueryText, "&WarehouseInfo", "InventoryAllocation.Warehouse = &SourceWarehouse");
		Query.SetParameter("SourceWarehouse", Filters.SourceWarehouse);
	Else
		QueryText = StrReplace(QueryText, "&WarehouseBalance", "TRUE");
		QueryText = StrReplace(QueryText, "&WarehouseInfo", "TRUE");
	EndIf;
	
	If Filters.Property("Purpose") Then
		QueryText = StrReplace(QueryText, "&PurposeBalance", "Purpose = &Purpose");
		QueryText = StrReplace(QueryText, "&PurposeOfInformation", "InventoryAllocation.Purpose = &Purpose");
		Query.SetParameter("Purpose", Filters.Purpose);
	Else
		QueryText = StrReplace(QueryText, "&PurposeBalance", "TRUE");
		QueryText = StrReplace(QueryText, "&PurposeOfInformation", "TRUE");
	EndIf;
	
	Query.Text = QueryText;
	Available2Balance = Query.Execute().Unload();
	
	Count = 0;
	Products = Undefined; Characteristic = Undefined; Purpose = Undefined; Warehouse = Undefined;
	For Counter = 0 To Available2Balance.Count() - 1 Do
		
		TableRow = Available2Balance[Counter];
		If Products <> TableRow.Products
				Or Characteristic <> TableRow.Characteristic
				Or Purpose <> TableRow.Purpose
				Or Warehouse <> TableRow.Warehouse Then
				
				Count = 0;
				Products   = TableRow.Products;
				Characteristic = TableRow.Characteristic;
				Purpose     = TableRow.Purpose;
				Warehouse          = TableRow.Warehouse;
				
		EndIf;
			
		Count = Count + TableRow.Count;
		TableRow.Count = Count;
		
	EndDo;
	
	QueryText =
		"SELECT ALLOWED
		|	InventoryAllocation.Products AS Products,
		|	InventoryAllocation.Characteristic AS Characteristic,
		|	InventoryAllocation.Purpose AS Purpose,
		|	InventoryAllocation.Warehouse AS Warehouse,
		|	InventoryAllocation.RequestShipmentOn AS DateOfShipment,
		|	MAX(ISNULL(ReportOrders.Priority.AddlOrderingAttribute, 1)) AS PriorityOfOrderingProps,
		|	ISNULL(ReportOrders.Priority, VALUE(Catalog.Priorities.EmptyRef)) AS Priority,
		|	SUM(InventoryAllocation.Count) AS Count
		|FROM
		|	InformationRegister.InventoryAllocation AS InventoryAllocation
		|		
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS ReportOrders
		|		ON ReportOrders.Ref = InventoryAllocation.ShipmentOrder
		|		 AND NOT ReportOrders.AdditionalRecord
		|WHERE
		|	InventoryAllocation.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|		AND InventoryAllocation.InventoryState = VALUE(Enum.InventoryStates.NotProvided)
		|		AND InventoryAllocation.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply))
		|		AND &Products
		|		AND &Characteristic
		|		AND &Purpose
		|		AND &ShopFloorStockroom
		|		AND &Warehouse
		|GROUP BY
		|	InventoryAllocation.Products,
		|	InventoryAllocation.Characteristic,
		|	InventoryAllocation.Purpose,
		|	InventoryAllocation.Warehouse,
		|	InventoryAllocation.RequestShipmentOn,
		|	ISNULL(ReportOrders.Priority, VALUE(Catalog.Priorities.EmptyRef))";
	
	If Filters.Property("Products") Then
		QueryText = StrReplace(QueryText, "&Products", "InventoryAllocation.Products = &Products");
		Query.SetParameter("Products", Filters.Products);
	Else
		QueryText = StrReplace(QueryText, "&Products", "TRUE");
	EndIf;
	
	If Filters.Property("Characteristic") Then
		QueryText = StrReplace(QueryText, "&Characteristic", "InventoryAllocation.Characteristic = &Characteristic");
		Query.SetParameter("Characteristic", Filters.Characteristic);
	Else
		QueryText = StrReplace(QueryText, "&Characteristic", "TRUE");
	EndIf;
	
	If Filters.Property("DestinationWarehouse") Then
		QueryText = StrReplace(QueryText, "&Warehouse", "InventoryAllocation.Warehouse = &DestinationWarehouse");
		Query.SetParameter("DestinationWarehouse", Filters.DestinationWarehouse);
	Else
		QueryText = StrReplace(QueryText, "&Warehouse", "TRUE");
	EndIf;
	
	If Filters.Property("Purpose") Then
		QueryText = StrReplace(QueryText, "&Purpose", "InventoryAllocation.Purpose = &Purpose");
		Query.SetParameter("Purpose", Filters.Purpose);
	Else
		QueryText = StrReplace(QueryText, "&Purpose", "TRUE");
	EndIf;
	
	If Filters.Property("FilterShopFloorStockroom") Then
		QueryText = StrReplace(QueryText, "&ShopFloorStockroom", "InventoryAllocation.Warehouse.ShopFloorStockroom = &ShopFloorStockroom");
		Query.SetParameter("ShopFloorStockroom", Filters.FilterShopFloorStockroom);
	Else
		QueryText = StrReplace(QueryText, "&ShopFloorStockroom", "TRUE");
	EndIf;
	
	Query.Text = QueryText;
	Demands = Query.Execute().Unload();
	
	Result = New Structure("Demands, Available2Balance", Demands, Available2Balance);
	Return Result;
	
EndFunction

Procedure AllocateQuantity(Result, TableOfNeeds, BalanceTable, FilterFields, FilterField_ = "")
	
	StructureOfResidueSelection = New Structure(FilterFields);
	For Each TableRow In TableOfNeeds Do
		
		If FilterField_ <> "" And Not TableRow[FilterField_] Then
			Continue;
		EndIf;
		
		FillPropertyValues(StructureOfResidueSelection, TableRow);
		FoundRows = BalanceTable.FindRows(StructureOfResidueSelection);
		
		For Each FoundRow In FoundRows Do
			
			If TableRow.Demand <= 0 Then
				Break;
			EndIf;
			
			If FoundRow.Available > 0 Then
				
				QuantityToDistribute = Min(FoundRow.Available, TableRow.Demand);
				TableRow.Demand = TableRow.Demand - QuantityToDistribute;
				
				NewRow = Result.Add();
				FillPropertyValues(NewRow, TableRow);
				NewRow.SourceWarehouse = FoundRow.SourceWarehouse;
				NewRow.WarehouseSenderName = FoundRow.WarehouseSenderName;
				NewRow.Available         = QuantityToDistribute;
				NewRow.Demand      = QuantityToDistribute;
				FoundRow.Available     = FoundRow.Available - QuantityToDistribute;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure FillInColumnsOfDetailedRecordsTable(DetailedRecords)
	
	DetailedRecords.Columns.Add("Period");
	DetailedRecords.Columns.Add("ForTransfer", New TypeDescription("Number"));
	DetailedRecords.Columns.Add("Warehouse");
	DetailedRecords.Columns.Add("Available");
	DetailedRecords.Columns.Add("WarehouseName");
	DetailedRecords.Columns.Add("Demand");
	DetailedRecords.Columns.Add("Priority");
	DetailedRecords.Columns.Add("PriorityOfOrderingProps");
	DetailedRecords.Columns.Add("DemandDate");
	DetailedRecords.Columns.Add("ThisIsOutsideThePeriodLimit");
	DetailedRecords.Columns.Add("ThisIsShortage");
	
EndProcedure

Function DetailedRecords(FillParameters) Export
	
	DetailedRecords = New ValueTable();
	FillInColumnsOfDetailedRecordsTable(DetailedRecords);
	
	Filters = New Structure();
	If ValueIsFilled(FillParameters.SourceWarehouse) Then
		Filters.Insert("SourceWarehouse", FillParameters.SourceWarehouse);
	EndIf;
	
	If ValueIsFilled(FillParameters.DestinationWarehouse) Then
		Filters.Insert("DestinationWarehouse", FillParameters.DestinationWarehouse);
	EndIf;
	
	FilterShopFloorStockroom = FilterShopFloorStockroom(FillParameters.RegistrationOption);
	
	If FilterShopFloorStockroom <> Undefined Then
		Filters.Insert("FilterShopFloorStockroom", FilterShopFloorStockroom);
	EndIf;
	
	Filters.Insert("Purpose",     FillParameters.Purpose);
	Filters.Insert("Products",   FillParameters.Products);
	Filters.Insert("Characteristic", FillParameters.Characteristic);
	
	ThisIsDistributionOfResiduals = FillParameters.Mode = "StockAllocation";
	GoodsTable = Goods(
		FillParameters.DateOfShipment,
		FillParameters.DateOfNextShipment,
		FillParameters.DemandsBeforeDate,
		Filters,
		ThisIsDistributionOfResiduals);
		
	WarehouseFields = ?(ThisIsDistributionOfResiduals,
		"WarehouseRecipientName,DestinationWarehouse",
		"WarehouseSenderName,SourceWarehouse");
	Columns = "Products,Characteristic,Purpose," + OrderColumns(ThisIsDistributionOfResiduals, WarehouseFields);
	GoodsTable.GroupBy(Columns, "Available,Demand");
	GoodsTable.Sort(Columns);
	
	QuantityIsAvailable    = 0;
	QuantityNeed = 0;
	
	For Each TableRow In GoodsTable Do
		
		QuantityIsAvailable     = QuantityIsAvailable    + TableRow.Available;
		QuantityNeed  = QuantityNeed + TableRow.Demand;
		
		If FillParameters.Mode = "StockAllocation" And TableRow.Demand > 0 Then
			
			NewRow = DetailedRecords.Add();
			
			NewRow.Period               = TableRow.Period;
			NewRow.Warehouse                = TableRow.DestinationWarehouse;
			NewRow.WarehouseName    = TableRow.WarehouseRecipientName;
			NewRow.PriorityOfOrderingProps = TableRow.PriorityOfOrderingProps;
			NewRow.DemandDate      = TableRow.DemandDate;
			NewRow.Demand          = TableRow.Demand;
			NewRow.Priority            = TableRow.Priority;
			
		ElsIf FillParameters.Mode = "Demand_fulfillment" And TableRow.Available > 0 Then
			
			NewRow = DetailedRecords.Add();
			
			NewRow.Warehouse                = TableRow.SourceWarehouse;
			NewRow.WarehouseName    = TableRow.WarehouseSenderName;
			NewRow.Available             = TableRow.Available;
			
		EndIf;
		
	EndDo;
	
	Result = New Structure("QuantityIsAvailable,QuantityNeed,DetailedRecords",
		QuantityIsAvailable,QuantityNeed,DetailedRecords);
	Return Result;
	
EndFunction

Procedure GoodsFillInServiceDetails(Goods)
	
	// The following data of the tabular part of the Goods are used for filling in:
	// - Nomenclature,
	// - Mark,
	// - Quantity.
	//
	// The following details of the form are filled in, linked to the tabular part of the Goods:
	// - Article,
	// - Packaging,
	// - Code,
	// - Weight,
	// - Weight units,
	// - Volume,
	// - The volume of the unit.
	
	QueryText =
		"SELECT
		|	SourceTable1.SearchStringNumber  AS SearchStringNumber,
		|	SourceTable1.Products AS Products,
		|	SourceTable1.Count   AS Count,
		|	SourceTable1.Mark      AS Mark
		|INTO TTTableSource
		|FROM
		|	&SourceTable1 AS SourceTable1
		|;
		|
		|////////////////////////////////////////////////
		|SELECT
		|	SourceTable1.SearchStringNumber  AS SearchStringNumber,
		|	
		|	SourceProducts.UnitOfMeasure AS Package,
		|	SourceProducts.Code      AS Code,
		|	SourceProducts.SKU  AS SKU,
		|	&QueryTextItemWeight   AS UnitWeight,
		|	&QueryTextTheVolumeOfTheItem AS UnitVolume,
		|	
		|	CASE WHEN SourceTable1.Mark THEN
		|			SourceTable1.Count * &QueryTextItemWeight
		|		ELSE
		|			0
		|	END                          AS Weight,
		|	
		|	CASE WHEN SourceTable1.Mark THEN
		|			SourceTable1.Count * &QueryTextTheVolumeOfTheItem
		|		ELSE
		|			0
		|	END                          AS VolumeM3
		|	
		|FROM
		|	TTTableSource AS SourceTable1
		|		
		|		LEFT JOIN Catalog.Products AS SourceProducts
		|		ON SourceProducts.Ref = SourceTable1.Products";
		
	QueryText = StrReplace(QueryText, "&QueryTextItemWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"SourceProducts.UnitOfMeasure",
			"SourceProducts"));
	
	QueryText = StrReplace(QueryText, "&QueryTextTheVolumeOfTheItem",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
			"SourceProducts.UnitOfMeasure",
			"SourceProducts"));
		
	Query = New Query(QueryText);
	
	SourceTable1 = Goods.Copy(, "SearchStringNumber,Products,Mark,Count");
	
	Query.SetParameter("SourceTable1", SourceTable1);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		LineProducts_ = Goods[Selection.SearchStringNumber - 1];
		FillPropertyValues(LineProducts_,
		                         Selection,
		                         "SKU,
		                         |Code,
		                         |Package,
		                         |Weight,
		                         |UnitWeight,
		                         |VolumeM3,
		                         |UnitVolume");
		
	EndDo;
	
EndProcedure

// Parameters:
//  Goods - ValueTable - Table of products.
//  WarehouseCart- ValueTable - Table of warehouses.
Procedure FillWarehouseBasket(Goods, WarehouseCart)
	
	WarehouseData = New Map();
	
	For Each TableRow In Goods Do
		
		For Each DetailRecord In TableRow.DetailedRecords Do
			
			Value = WarehouseData.Get(DetailRecord.Warehouse);
			If Value = Undefined Then
				
				Value = New Structure("Weight,VolumeM3,FrequencyOfLines,FrequencyOfLinesWithZeroWeight,FrequencyOfLinesWithZeroVolume");
				Value.Weight                         = 0;
				Value.VolumeM3                       = 0;
				Value.FrequencyOfLines                = 0;
				Value.FrequencyOfLinesWithZeroWeight   = 0;
				Value.FrequencyOfLinesWithZeroVolume = 0;
				
				WarehouseData.Insert(DetailRecord.Warehouse, Value);
				
			EndIf;
			
			Value.Weight     = Value.Weight   + TableRow.UnitWeight   * DetailRecord.ForTransfer;
			Value.VolumeM3   = Value.VolumeM3 + TableRow.UnitVolume * DetailRecord.ForTransfer;
			Value.FrequencyOfLines = Value.FrequencyOfLines + 1;
			
			Value.FrequencyOfLinesWithZeroWeight   = Value.FrequencyOfLinesWithZeroWeight   + ?(TableRow.UnitWeight   = 0, 0, 1);
			Value.FrequencyOfLinesWithZeroVolume = Value.FrequencyOfLinesWithZeroVolume + ?(TableRow.UnitVolume = 0, 0, 1);
			
		EndDo;
		
	EndDo;
	
	For Each Item In WarehouseData Do
		
		NewRow = WarehouseCart.Add();
		FillPropertyValues(NewRow, Item.Value);
		NewRow.Warehouse = Item.Key;
		NewRow.ShowsThatThereAreLinesWithZeroWeight   = ?(Value.FrequencyOfLinesWithZeroWeight   = 0, 0, 1);
		NewRow.ShowsThatThereAreLinesWithZeroVolume = ?(Value.FrequencyOfLinesWithZeroVolume = 0, 0, 1);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
