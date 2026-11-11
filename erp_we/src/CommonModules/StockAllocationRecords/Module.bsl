////////////////////////////////////////////////////////////////////////////////
// The module "Distribution of stocks (movements)" contains procedures and functions
// that serve the movement of documents on the register of accumulation "Distribution of stocks - Movements".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - FixedStructure - document properties (See DocumentsPosting.DocumentProperties)
//                                      .
//
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	Parameters.ThereAreDerivedMotions = True;
	
	DocumentType = TypeOf(Document);
	
	AdditionalDocuments_ = New Structure;
	DocumentsPostingLocalization.FillInLocalCollateralDocuments(AdditionalDocuments_);
	Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.InventoryAndDemands);
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.InventoryAndDemands);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then

			CorrectiveDocument = DocumentCorrection.ThisIsCorrectiveDocument(Document);
		
		If Not InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(Document)
			And (Not Document.AdditionalProperties.Property("ControlSupply")
				Or Document.AdditionalProperties.ControlSupply) Then
			
				If DocumentType = Type("DocumentObject.DiscrepancyReportFollowingShipment")
					Or DocumentType = Type("DocumentObject.DiscrepancyReportFollowingTransfer")
					Or DocumentType = Type("DocumentObject.InventoryConsumption")
					Or DocumentType = Type("DocumentObject.ReturnOfGoodsToVendor")
					Or DocumentType = Type("DocumentObject.SalesOrder")
					Or DocumentType = Type("DocumentObject.InventoryConsumptionOrder")
					Or DocumentType = Type("DocumentObject.TransferOrder")
					Or DocumentType = Type("DocumentObject.ByAssemblyDisassemblyOrder")
					Or DocumentType = Type("DocumentObject.InventoryAssignmentAdjustment")
						And Not Document.AdditionalProperties.Property("SoftwareDocumentCreation")
					Or DocumentType = Type("DocumentObject.PurchaseOrder")
					Or DocumentType = Type("DocumentObject.PurchaseRequest")
					Or DocumentType = Type("DocumentObject.SaleAdjustment")
					Or DocumentType = Type("DocumentObject.GoodsShipmentToCustomer")
					Or DocumentType = Type("DocumentObject.GoodsShipmentFromStorage")
						And Not Document.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
					Or DocumentType = Type("DocumentObject.GoodsShipmentFromStorage")
						And Not UserRightsCached.DisableControlOfManufacturedProductTransferToProvider()
					Or DocumentType = Type("DocumentObject.RetailSalesReport")
					Or DocumentType = Type("DocumentObject.TransferOfGoodsToBailee")
					Or DocumentType = Type("DocumentObject.InventoryTransfer")
					Or DocumentType = Type("DocumentObject.ReceiptOfGoodsToWarehouse")
					Or DocumentType = Type("DocumentObject.GoodsReceiptFromCustomer")
					Or DocumentType = Type("DocumentObject.ReceiptOfGoodsFromCustodian")
					Or DocumentType = Type("DocumentObject.GoodsReceiptForStorage")
					Or DocumentType = Type("DocumentObject.VendorInvoice")
					Or DocumentType = Type("DocumentObject.GoodsReceiptNote")
					Or DocumentType = Type("DocumentObject.OtherGoodsRecordingAsReceived")
					Or DocumentType = Type("DocumentObject.CustomerInvoice")
					Or DocumentType = Type("DocumentObject.AssemblyFromComponents")
					Or DocumentType = Type("DocumentObject.CashRegisterReceipt")
					Or DocumentType = Type("DocumentObject.CashRegisterReceiptReturn")
					Or DocumentType = Type("DocumentObject.ReceiptOfCashRegisterAdjustment")
					Or DocumentType = Type("DocumentObject.GoodsQualityControlCertificate")
					Or DocumentType = Type("DocumentObject.RequestForGoodsQualityControl")
						And Document.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods
					
					Or DocumentType = Type("DocumentObject.MovementOfProductsAndMaterials")
						And Not Document.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom
					Or DocumentType = Type("DocumentObject.MovementOfProductsAndMaterials")
						And Not UserRightsCached.AllowRetroactiveReleaseRegistration()
					Or DocumentType = Type("DocumentObject.OrderOfMaterialsForProduction")
					Or DocumentType = Type("DocumentObject.SubcontractOrder2_5")
						And Not Document.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
					Or DocumentType = Type("DocumentObject.RequestForReturnOfGoodsFromCustomer")
					Or DocumentType = Type("DocumentObject.BackflushProduction")
					
					Or DocumentType = Type("DocumentObject.MaterialProviderOrder2_5")
					Or DocumentType = Type("DocumentObject.ProductionOrder2_2")
					Or DocumentType = Type("DocumentObject.RMOrder")
					Or DocumentType = Type("DocumentObject.ProductionStage2_2")
					Or DocumentType = Type("DocumentObject.ReportToMaterialProvider2_5")
					Or CorrectiveDocument
						And Not Document.AdditionalProperties.Property("SoftwareDocumentCreation") 
					
					Or (AdditionalDocuments_.Property("ControlRegistersOfChanges")
						And AdditionalDocuments_.ControlRegistersOfChanges.Property("InventoryAndDemands")
						And AdditionalDocuments_.ControlRegistersOfChanges.InventoryAndDemands.Find(DocumentType)<>Undefined)
					Then
						Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.InventoryAndDemands);
			EndIf;
			
		EndIf;
	
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.InventoryAndDemands;
	AddlCondition = "RegisterData.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)";
	TextOfReversal = DocumentsPosting.TextOfReversingRequest(RegisterMetadata, MetadataOfDocument, AddlCondition);
	QueriesTexts.Insert(RegisterMetadata.FullName(), TextOfReversal);
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers security.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "InventoryAndDemands");
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList of String - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "InventoryAndDemandsUpdate") Then
		
		ParameterValue = Users.RolesAvailable(
			"PostUnconfirmedOrdersBeyondAssignedDemand", Undefined, False);
		Query.SetParameter("MonitorConfirmedReceiptSchedule", ParameterValue);
		Query.SetParameter("ControlBalanceOfGoodsToBeReservedUponReceipt",
			Constants.ControlBalanceOfGoodsToBeReservedUponReceipt.Get());
		Query.SetParameter("MonitorOnlyActualBalance",
			TypeOf(Document.Ref) = Type("DocumentRef.RequestForGoodsQualityControl"));
		
		InventoryAllocation.AddTextOfControlRequest(Query, QueryTexts, Document);
		
	EndIf;
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "InventoryAndDemandsUpdate") Then
		
		TableOfControlResults = ControlResults.EnsuringControlResults;
		InventoryAllocation.ReportErrorsDuring(Document, Cancel, TableOfControlResults);
		
		If ControlResults.Property("ProvisionResultsOfControlOfExcessOfSeparateProvision") Then
			TableOfControlResults = ControlResults.ProvisionResultsOfControlOfExcessOfSeparateProvision;
			InventoryAllocation.ReportErrorsInImplementationExceedingSeparateProvision(Document,
				Cancel, TableOfControlResults);
		EndIf;
		
		If ControlResults.Property("SupplyResultsOfInventoryControlOfControlledLotReferenceInWarehouse") Then
			TableOfControlResults = ControlResults.SupplyResultsOfInventoryControlOfControlledLotReferenceInWarehouse;
			InventoryAllocation.ReportErrorsInInventoryOfControlledLotReferenceInWarehouse(Document,
				Cancel, TableOfControlResults);
		EndIf;
		
	EndIf;
	
EndProcedure

// Reallocates inventory when the priority of shipment orders is changed in a group.
// 
// Parameters:
// 	Orders - Array - links to the orders.
//
Procedure WhenChangingPriority(Orders) Export
	
	If Orders.Count() = 0 Then
		Return;
	EndIf;
	TempTablesManager = New TempTablesManager();
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Orders", Orders);
	Query.Text =
		"SELECT DISTINCT
		|	InformationRecords.Products AS Products,
		|	InformationRecords.Characteristic AS Characteristic,
		|	InformationRecords.Warehouse AS Warehouse,
		|	InformationRecords.Purpose AS Purpose,
		|	UNDEFINED AS OrderDocument,
		|	0 AS InStockExpense,
		|	0 AS ReserveAtWarehouse
		|INTO InventoryAndDemandsUpdate
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(, OrderDocument IN(&Orders)) AS InformationRecords
		|WHERE
		|	InformationRecords.ToSupplyBalance <> 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
	SetPrivilegedMode(True);
	Query.Execute();
	Document = DocumentsPosting.DocumentEmulation(Orders[0], Undefined); // need a link to the order, for the mechanism of States of customer orders
	
	BeginTransaction();
	Try
		
		DocumentEmulation = DocumentsPosting.DocumentEmulation(Undefined, Undefined);
		ReflectInventoryAllocationTasks(DocumentEmulation, TempTablesManager);
		If Not InventoryAllocation.CountRegisterWithRoutineTask() Then
			DocumentsStates.ReflectDocumentStates(Document, TempTablesManager);
			OrderStructureDocumentPosting.CreateTasksForCalculatingStructureOfOrderDistributionOfInventoryWhenWritingDocument(Document, TempTablesManager);
		EndIf;
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		ErrorText = DetailErrorDescription(ErrorInfo());
		MessageText = NStr("vi = 'Không thể thay đổi thành công mức độ ưu tiên đơn hàng do nguyên nhân: %Cause%';
							|ru = 'Изменение приоритета заказа завершилось неудачно по причине: %Cause%';
							|en = 'Order priority change failed. Reason: %Cause%'; fa = 'Order priority change failed. Reason: %Cause%';
							|it = 'Modifica della priorità dell''ordine non è riuscita a causa di: %Cause%';
							|pl = 'Zmiana priorytetu zamówienia zakończyło się nieudanie z powodu: %Cause%';
							|tr = 'Sipariş önceliği değişikliği şu nedenle başarısız oldu: %Cause%'");
		MessageText = StrReplace(MessageText, "%Cause%", ErrorText);
		LogEvent = InfobaseUpdate.EventLogEvent();
		WriteLogEvent(LogEvent,
		                         EventLogLevel.Error,
		                         Metadata.InformationRegisters.JobsForAllocatingInventory,
		                         ,
		                         MessageText);
		Raise MessageText;
		
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Document movement patterns.

// Supplements the texts of the request for the document with the texts of Registered Records of the inventory of need
// Reflects the operation of the Registered Recording of goods for shipment (write-off from the available Balance).
// Reduces the actual and free Balance of goods in the warehouse, work in the department.
// Document execution can be performed with Balance control.
// If the free Balance is not sufficient, the stocks in the warehouse
// distributed earlier to the specified document of the planned inventory consumption may be used.
//
// Parameters:
//  Query - Query - Request for document reflection.
//  QueryTexts - ValueList of String - List of document reflection request texts.
//  Registers - Undefined, Structure, String - List of registers to reflect.
//  QueryTextTabPart - String - The text of the request to receive document data. The selection expressions must contain the following fields:
//   * Ref                                     - DocumentRef                        - the reflected document.
//   * Period                                     - Date                                  - the date when the operation was reflected (corresponds to the date of the document).
//   * Products                               - CatalogRef.Products         - the item that is being written off from the inventory.
//   * Characteristic                             - CatalogRef.ItemsCharacteristics - a characteristic of the item that is being written off from the inventory.
//   * Warehouse                                      - CatalogRef.Warehouses               - write-off warehouse.
//   * Purpose                                 - CatalogRef.Assignments           - the purpose of the nomenclature.
//   * ControlledLotReference                       - CatalogRef.ControlledLots - The Lot reference received for quality control,
//                                                                                          which is shipped by transfer, written off or successfully completed control.
//   * Count                                 - Number                                 - the amount to be debited.
//   * PlannedConsumptionOfDistributedStock - DefinedType.ExpectedShipment     - an inventory expense planning document
//                                                                                          whose allocated inventory will be consumed.
//   * ControlOfFreeResidue                  - Boolean                                - control of the free balance in the write-down of inventories.
//  ThereIsControlledLotReference                      - Boolean                                - true if the Controlled Party field in the document may not be empty.
//  TemporaryTableTemplateTexts - See DocumentsPosting.AddDocumentReflectionRequest.TemporaryTableTemplateTexts
Procedure StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, ThereIsControlledLotReference, TemporaryTableTemplateTexts = Undefined) Export
	
	QueryTextOperations =
		// Inventory expense.
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	CASE
		|		WHEN TabPart.ControlOfFreeResidue
		|			THEN VALUE(AccumulationRecordType.Expense)
		|		ELSE VALUE(AccumulationRecordType.Receipt)
		|	END AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	UNDEFINED AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	CASE
		|		WHEN TabPart.ControlOfFreeResidue
		|			THEN TabPart.Count
		|		ELSE -TabPart.Count
		|	END AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	TabPart.PlannedConsumptionOfDistributedStock AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
		
	If ThereIsControlledLotReference Then
		
		Texts = New Array();
		Texts.Add(QueryTextOperations);
		
		QueryTextOperations =
		// Expense of the blocked inventory.
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	CASE
		|		WHEN TabPart.ControlOfFreeResidue
		|			THEN VALUE(AccumulationRecordType.Expense)
		|		ELSE VALUE(AccumulationRecordType.Receipt)
		|	END AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	CASE
		|		WHEN TabPart.ControlOfFreeResidue
		|			THEN TabPart.Count
		|		ELSE -TabPart.Count
		|	END AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	TabPart.PlannedConsumptionOfDistributedStock AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
		
		Texts.Add(QueryTextOperations);
		QueryTextOperations = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf;
	
	ReflectionTemplateTexts = ReflectionTemplateTexts(Registers, QueryTextOperations, "InventoryAndDemands");
	QueryTextsOfDocumentTables = New Structure;
	QueryTextsOfDocumentTables.Insert("TabPart", QueryTextTabPart);
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts,
		QueryTextsOfDocumentTables, TemporaryTableTemplateTexts);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of Registered Records of the inventory register.
// Reflects the operation of the planned consumption of goods.
// Reserve: reduces the free Balance with Balance control, creates a reserve of goods in stock by order.
// Unsecured: does not form needs and reserves, records the fact of order acceptance
// If there is a free Balance in the warehouse / in the expected receipts: reduces the free Balance,
// forms a reserve of goods in the warehouse for zakazukobesupply, if there is no free Balance in the warehouse / in the expected receipts: forms the need for goods / works.
//
// Parameters:
//  Query - Query - Request for document reflection.
//  QueryTexts - ValueList of String - List of document reflection request texts.
//  Registers - Undefined, Structure, String - List of registers to reflect.
//  QueryTextTabPart - String - The text of the request to receive document data. The selection expressions must contain the following fields:
//   * Ref                                     - DocumentRef                         - the reflected document.
//   * Period                                     - Date                                   - the date when the operation was reflected (corresponds to the date of the document).
//   * Products                               - CatalogRef.Products          - the item that is being written off from the inventory.
//   * Characteristic                             - CatalogRef.ItemsCharacteristics - a characteristic of the item that is being written off from the inventory.
//   * Warehouse                                      - CatalogRef.Warehouses                - write-off warehouse.
//   * Purpose                                 - CatalogRef.Assignments            - the purpose of the nomenclature.
//   * ControlledLotReference                       - CatalogRef.ControlledLots  - Lot reference of items under control, scheduled to be shipped by transfer order
//   * Count                                 - Number                                  - the quantity to be ordered.
//   * SupplyOption                         - EnumRef.SupplyOptions - the version of the software.
//   * OrderDocument                                      - DefinedType.ExpectedShipment      - order.
//   * RequestShipmentOn                       - Date                                   - planned date of inventory write-off.
//   * OnSchedule                                  - Boolean - indicates that the consumption of the product occurs according to the previously planned consumption in the schedule.
//   * OrderInSchedule                       - DefinedType.ExpectedShipment      - a document for planning the consumption
//                                                                                           of the inventory that will be reduced.
//   * QuantityInGraph                         - Number                                  - the amount of stock by which the stock
//                                                                                           of the previously planned consumption in the schedule will be reduced.
//  ThereIsBySchedule                                 - Boolean                                 - true if the image field in the document can be true.
Procedure PlanStockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, ThereIsBySchedule) Export
	
	QueryTextOperations =
		// Shipping schedule.
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	CASE
		|		WHEN TabPart.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN TabPart.OrderDocument
		|		ELSE TabPart.ControlledLotReference
		|	END AS OrderDocument,
		|	CASE
		|		WHEN TabPart.RequestShipmentOn = UNDEFINED
		|			THEN DATETIME(1,1,1)
		|		ELSE TabPart.RequestShipmentOn
		|	END AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	CASE
		|		WHEN TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN 0
		|		WHEN TabPart.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS ReserveAtWarehouse,
		|	CASE
		|		WHEN TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN 0
		|		WHEN TabPart.SupplyOption = VALUE(Enum.SupplyOptions.ReserveAsReceived)
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	CASE
		|		WHEN TabPart.SupplyOption = VALUE(Enum.SupplyOptions.ToSupply)
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS ToSupply,
		|	CASE
		|		WHEN TabPart.SupplyOption = VALUE(Enum.SupplyOptions.NotRequired)
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	CASE
		|		WHEN TabPart.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN 0
		|		WHEN TabPart.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS ReserveAtWarehouseFromLocked,
		|	CASE
		|		WHEN TabPart.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN 0
		|		WHEN TabPart.SupplyOption = VALUE(Enum.SupplyOptions.ReserveAsReceived)
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND TabPart.Count <> 0
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
		
	If ThereIsBySchedule Then
		
		Texts = New Array();
		Texts.Add(QueryTextOperations);
		
		QueryTextOperations =
		// Closing of the shipment schedule.
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	CASE
		|		WHEN TabPart.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN TabPart.OrderInSchedule
		|		ELSE TabPart.ControlledLotReference
		|	END AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS BlockedInWarehouse,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	TabPart.QuantityInGraph AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND TabPart.OnSchedule
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
		
		Texts.Add(QueryTextOperations);
		QueryTextOperations = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf;
	
	ReflectionTemplateTexts = ReflectionTemplateTexts(Registers, QueryTextOperations, "InventoryAndDemands");
	QueryTextsOfDocumentTables = New Structure;
	QueryTextsOfDocumentTables.Insert("TabPart", QueryTextTabPart);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, QueryTextsOfDocumentTables);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of Registered Records of the inventory of need
// Reflects the operation of canceling the planned consumption of goods from the warehouse.
//
// Parameters:
//  Query - Query - Request for document reflection.
//  QueryTexts - ValueList of String - List of document reflection request texts.
//  Registers - Undefined, Structure, String - List of registers to reflect.
//  QueryTextTabPart - String - The text of the request to receive document data. The selection expressions must contain the following fields:
//   * Ref                                     - DocumentRef                         - the reflected document.
//   * Period                                     - Date                                   - the date when the operation was reflected (corresponds to the date of the document).
//   * Products                               - CatalogRef.Products          - the item that is being written off from the inventory.
//   * Characteristic                             - CatalogRef.ItemsCharacteristics - a characteristic of the item that is being written off from the inventory.
//   * Warehouse                                      - CatalogRef.Warehouses -              - write-off warehouse.
//   * Purpose                                 - CatalogRef.Assignments -          - the purpose of the nomenclature.
//   * ControlledLotReference                       - CatalogRef.ControlledLots  - Lot reference of items under control, scheduled to be shipped by transfer order
//   * Count                                 - Number                                  - the quantity to cancel.
//   * OrderInSchedule                       - DefinedType.ExpectedShipment      - a document for planning the consumption
//                                                                                           of the inventory that will be reduced.
Procedure CancelPlannedStockExpense(Query, QueryTexts, Registers, QueryTextTabPart) Export
	
	QueryTextOperations =
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	CASE
		|		WHEN TabPart.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN TabPart.OrderInSchedule
		|		ELSE TabPart.ControlledLotReference
		|	END AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	TabPart.Count AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
		
	ReflectionTemplateTexts = ReflectionTemplateTexts(Registers, QueryTextOperations, "InventoryAndDemands");
	QueryTextsOfDocumentTables = New Structure;
	QueryTextsOfDocumentTables.Insert("TabPart", QueryTextTabPart);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, QueryTextsOfDocumentTables);
	
EndProcedure

// supplements the texts of the request for the document with the texts of the movements of the inventory register
// and the inventory register, reflecting the operation of the actual receipt of goods to the warehouse
// (replenishment of the available Balance).
// increases the actual and free Balance of goods in the warehouse, work in the division.
// if the arrival of the goods was previously planned by the document of the planned arrival of the stock (arrival on schedule),
// then the stock and the free Balance in this expected arrival (disposal) will be reduced.
//
// Parameters:
//  Query - Query - Request for document reflection.
//  QueryTexts - ValueList of String - List of document reflection request texts.
//  Registers - Undefined, Structure, String - List of registers to reflect.
//  QueryTextTabPart - String - The text of the request to receive document data. The selection expressions must contain the following fields:
//   * Ref                    - DocumentRef                        - the reflected document.
//   * Period                    - Date                                  - the date when the operation was reflected (corresponds to the date of the document).
//   * Products              - CatalogRef.Products         - the incoming item.
//   * Characteristic            - CatalogRef.ItemsCharacteristics - the received characteristic of the nomenclature.
//   * Warehouse                     - CatalogRef.Warehouses               - warehouse of registration.
//   * Purpose                - CatalogRef.Assignments           - the purpose of the incoming nomenclature.
//   * ControlledLotReference      - CatalogRef.ControlledLots - Lot reference received at the warehouse and subject to quality control.
//   * ToControlQuality - Boolean                                - the need to block the incoming item.
//   * SubjectToUnlocking     - Boolean                                - formation of the item unblocking schedule.
//   * QualityConfirmationDate - Date                                  - planned Date of quality confirmation after quality control 
//   * Count                - Number                                 - the amount to be received.
//   * OnSchedule                 - Boolean                                - indicates that the arrival of the product occurs according to the previously scheduled receipt in the schedule.
//   * OrderInSchedule      - DefinedType.ExpectedReceipt  - a document for planning the inventory arrival,
//                                                                         the inventory of which will be reduced by the amount of this inventory arrival.
//  ThereIsBySchedule                - Boolean                                - true if the image field in the document can be true.
//  ThereIsToCheckQuality - Boolean                               - true if the Quality control field in the document may not be empty.
//  TemporaryTableTemplateTexts - See DocumentsPosting.AddDocumentReflectionRequest.TemporaryTableTemplateTexts
Procedure StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, ThereIsBySchedule,
						ThereIsToCheckQuality, TemporaryTableTemplateTexts = Undefined) Export
	
	QueryTextOperations =
		// The goods arrive at the warehouse.
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	UNDEFINED AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	TabPart.Count AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
	
	If ThereIsToCheckQuality Then
		
		Texts = New Array();
		Texts.Add(QueryTextOperations);
		
		QueryTextOperations =
		// Item blocking in the warehouse.
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	TabPart.Count AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	TabPart.Count > 0 AND TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND TabPart.ToControlQuality
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))
		|
		|UNION ALL
		|
		// Planning the unblocking of incoming goods, for positive arrivals.
		|SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS OrderDocument,
		|	TabPart.QualityConfirmationDate AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	TabPart.Count AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND TabPart.ToControlQuality
		|		AND TabPart.SubjectToUnlocking
		|		AND TabPart.Count > 0
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
		
		Texts.Add(QueryTextOperations);
		QueryTextOperations = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	
	EndIf;
	
	If ThereIsBySchedule Then
		
		Texts = New Array();
		Texts.Add(QueryTextOperations);
		
		QueryTextOperations =
		// Closing the receipt schedule and the unlocking schedule.
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.OrderInSchedule AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	TabPart.Count AS CloseReceiptSchedule,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND TabPart.OnSchedule
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
		
		Texts.Add(QueryTextOperations);
		QueryTextOperations = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf;
	
	ReflectionTemplateTexts = ReflectionTemplateTexts(Registers, QueryTextOperations, "InventoryAndDemands");
	QueryTextsOfDocumentTables = New Structure;
	QueryTextsOfDocumentTables.Insert("TabPart", QueryTextTabPart);
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts,
		QueryTextsOfDocumentTables, TemporaryTableTemplateTexts);
	
EndProcedure

// supplements the texts of the request for the document with the texts of the movements of the inventory register
// and the inventory register, reflecting the operation of the actual receipt of goods to the warehouse
// (replenishment of the available Balance).
// increases the actual and free Balance of goods in the warehouse, work in the division.
// if the arrival of the goods was previously planned by the document of the planned arrival of the stock (arrival on schedule),
// then the stock and the free Balance in this expected arrival (disposal) will be reduced.
//
// Parameters:
//  Query - Query - Request for document reflection.
//  QueryTexts - ValueList of String - List of document reflection request texts.
//  Registers - Undefined, Structure, String - List of registers to reflect.
//  QueryTextTabPart - String - The text of the request to receive document data. The selection expressions must contain the following fields:
//   * Ref                    - DocumentRef                        - the reflected document.
//   * Period                    - Date                                  - the date when the operation was reflected (corresponds to the date of the document).
//   * Products              - CatalogRef.Products         - the incoming item.
//   * Characteristic            - CatalogRef.ItemsCharacteristics - the received characteristic of the nomenclature.
//   * Warehouse                     - CatalogRef.Warehouses               - warehouse of registration.
//   * Purpose                - CatalogRef.Assignments           - the purpose of the incoming nomenclature.
//   * ToControlQuality - Boolean                                - the need to block the item when it arrives at the warehouse.
//   * SubjectToUnlocking     - Boolean                                - formation of the item unblocking schedule.
//   * QualityConfirmationDate - Date                                  - the planned date of quality confirmation after the completion of the input quality control 
//   * Count                - Number                                 - the amount to be received.
//   * OrderDocument                     - DefinedType.ExpectedReceipt  - the order for which the receipt is planned.
//   * DateOfReceipt           - Boolean                                - the date on which the receipt is planned.
//   * AvailableForConsumption        - Boolean                                - indicates that this inventory can be used to meet the planned inventory consumption.
//   * OnSchedule                 - Boolean                                - indicates that the arrival of the product occurs according to the previously scheduled receipt in the schedule.
//   * OrderInSchedule      - DefinedType.ExpectedReceipt  - a document for planning the arrival
//                                                                         of the inventory that will be reduced.
//   * QuantityInGraph        - Number                                 - the amount of stock by which the stock previously planned in the receipt schedule will be reduced.
//  ThereIsBySchedule                - Boolean                                - true if the image field in the document can be true.
//  ThereIsToCheckQuality - Boolean                               - true if the Quality control field in the document may not be empty.
Procedure ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, ThereIsBySchedule, ThereIsToCheckQuality) Export
	
	QueryTextOperations =
		// Admission schedule.
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.OrderDocument AS OrderDocument,
		|	CASE
		|		WHEN TabPart.AvailableForConsumption
		|			THEN BEGINOFPERIOD(TabPart.DateOfReceipt, DAY)
		|		ELSE DATETIME(1, 1, 1)
		|	END AS EventDate,
		|	0 AS InStock,
		|	CASE
		|		WHEN TabPart.AvailableForConsumption
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS Received_1,
		|	TabPart.Count AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	CASE
		|		WHEN TabPart.AvailableForConsumption AND TabPart.ToControlQuality
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	TabPart.ToControlQuality AND TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND TabPart.Count <> 0
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
		
	If ThereIsToCheckQuality Then
		
		Texts = New Array();
		Texts.Add(QueryTextOperations);
		
		QueryTextOperations =
		// The unlocking schedule.
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.OrderDocument AS OrderDocument,
		|	TabPart.QualityConfirmationDate AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	TabPart.Count AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND TabPart.AvailableForConsumption
		|		AND TabPart.ToControlQuality
		|		AND TabPart.SubjectToUnlocking
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
			
		Texts.Add(QueryTextOperations);
		QueryTextOperations = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf;
	
	If ThereIsBySchedule Then
		
		Texts = New Array();
		Texts.Add(QueryTextOperations);
		
		QueryTextOperations =
		// Closing the admission schedule.
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.OrderInSchedule AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	TabPart.QuantityInGraph AS CloseReceiptSchedule,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN (&Ref)
		|		AND TabPart.OnSchedule
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
		
		Texts.Add(QueryTextOperations);
		QueryTextOperations = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf;
	
	ReflectionTemplateTexts = ReflectionTemplateTexts(Registers, QueryTextOperations, "InventoryAndDemands");
	QueryTextsOfDocumentTables = New Structure;
	QueryTextsOfDocumentTables.Insert("TabPart", QueryTextTabPart);
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, QueryTextsOfDocumentTables);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of Registered Records of the inventory register.
// Reflects the operation of canceling the scheduled arrival of goods at the warehouse.
// Increases the actual and free Balance of goods in the warehouse, work in the department.
// The stock and the free Balance in the expected arrival (disposal) will be reduced.
//
// Parameters:
//  Query - Query - Request for document reflection.
//  QueryTexts - ValueList of String - List of document reflection request texts.
//  Registers - Undefined, Structure, String - List of registers to reflect.
//  QueryTextTabPart - String - The text of the request to receive document data. The selection expressions must contain the following fields:
//   * Ref                    - DocumentRef                        - the reflected document.
//   * Period                    - Date                                  - the date when the operation was reflected (corresponds to the date of the document).
//   * Products              - CatalogRef.Products         - the incoming item.
//   * Characteristic            - CatalogRef.ItemsCharacteristics - the received characteristic of the nomenclature.
//   * Warehouse                     - CatalogRef.Warehouses               - warehouse of registration.
//   * Purpose                - CatalogRef.Assignments           - the purpose of the incoming nomenclature.
//   * ToControlQuality - Boolean                                - the need to close the receipt schedule of the blocked goods.
//   * SubjectToUnlocking     - Boolean                                - the need to close the item unlocking schedule.
//   * Count                - Number                                 - the quantity to cancel.
//   * OrderInSchedule      - DefinedType.ExpectedReceipt  - a document for planning the arrival
//                                                                         of the inventory that will be reduced.
Procedure CancelScheduledStockArrival(Query, QueryTexts, Registers, QueryTextTabPart) Export
	
	QueryTextOperations =
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.OrderInSchedule AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	TabPart.Count AS CloseReceiptSchedule,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref IN(&Ref)
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
	
	ReflectionTemplateTexts = ReflectionTemplateTexts(Registers, QueryTextOperations, "InventoryAndDemands");
	QueryTextsOfDocumentTables = New Structure;
	QueryTextsOfDocumentTables.Insert("TabPart", QueryTextTabPart);
	
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, QueryTextsOfDocumentTables);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the movements of the inventory register,
// reflecting the operation of scheduling the shipment schedule by dates, as well as the movement of goods to shipment.
//
// Parameters:
//  QueryTextTabPart - String - The text of the request to receive document data. The selection expressions must contain the following fields:
//   * Period                                     - Date                                   - the date when the operation was reflected (corresponds to the date of the document).
//   * Products                               - CatalogRef.Products          - the item that is being written off from the inventory.
//   * Characteristic                             - CatalogRef.ItemsCharacteristics - a characteristic of the item that is being written off from the inventory.
//   * Warehouse                                      - CatalogRef.Warehouses                - write-off warehouse.
//   * Purpose                                 - CatalogRef.Assignments            - the purpose of the nomenclature.
//   * ControlledLotReference                       - CatalogRef.ControlledLots  - The Lot reference of the item is under control, which needs to be shipped or scheduled to be shipped.
//   * Count                                 - Number                                  - the quantity to be ordered.
//   * SupplyOption                         - EnumRef.SupplyOptions - the version of the software.
//   * ShipmentOrder                            - DefinedType.ExpectedShipment      - order.
//   * RequestShipmentOn                       - Date                                   - planned date of inventory write-off.
//   * DateOfAdmission - Date - 
//   * OrderByPriority - Number - 
//   * ReadyForSupply - Boolean - 
//   * ReadyToShip - Boolean - 
//  IgnoreReadinessToProvide - Boolean -
//
//	Returns:
//   String - query text.
Function RequestTextOrderForProvisionAndShipment(QueryTextTabPart, IgnoreReadinessToProvide) Export
	
	QueryTextOperations =
		"SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	UNDEFINED AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	TabPart.Count AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	TabPart.PlannedConsumptionOfDistributedStock AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref = &Ref
		|		AND TabPart.Count <> 0
		|		AND TabPart.ReadyToShip
		|		AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))
		|
		|UNION ALL
		|
		|SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS OrderDocument,
		|	DATETIME(1,1,1) AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	0 AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	TabPart.Count AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	TabPart.PlannedConsumptionOfDistributedStock AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref = &Ref
		|		AND TabPart.Count <> 0
		|		AND TabPart.ReadyToShip
		|		AND TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
		|		AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))
		|
		|UNION ALL
		|
		|SELECT
		|	TabPart.Ref AS Recorder,
		|	TabPart.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	CASE
		|		WHEN TabPart.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN TabPart.ShipmentOrder
		|		ELSE TabPart.ControlledLotReference
		|	END AS OrderDocument,
		|	CASE WHEN TabPart.RequestShipmentOn = UNDEFINED THEN
		|				DATETIME(1,1,1)
		|			ELSE
		|				TabPart.RequestShipmentOn
		|		END AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	CASE
		|		WHEN TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN 0
		|		WHEN TabPart.SupplyOption IN(
		|				VALUE(Enum.SupplyOptions.FromWarehouse),
		|				VALUE(Enum.SupplyOptions.Ship))
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS ReserveAtWarehouse,
		|	CASE
		|		WHEN TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN 0
		|		WHEN TabPart.ReadyForSupply AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.ReserveAsReceived)
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS ReserveAsReceived,
		|	0 AS SnoozeReservation,
		|	CASE
		|		WHEN TabPart.ReadyForSupply AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.ToSupply)
		|			THEN TabPart.Count
		|			ELSE 0
		|	END AS ToSupply,
		|	CASE
		|		WHEN TabPart.SupplyOption = VALUE(Enum.SupplyOptions.NotRequired)
		|				OR NOT TabPart.ReadyForSupply AND TabPart.SupplyOption IN(
		|						VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|						VALUE(Enum.SupplyOptions.ToSupply))
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	CASE
		|		WHEN TabPart.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN 0
		|		WHEN TabPart.SupplyOption IN(
		|				VALUE(Enum.SupplyOptions.FromWarehouse),
		|				VALUE(Enum.SupplyOptions.Ship))
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS ReserveAtWarehouseFromLocked,
		|	CASE
		|		WHEN TabPart.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN 0
		|		WHEN TabPart.ReadyForSupply AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.ReserveAsReceived)
		|			THEN TabPart.Count
		|		ELSE 0
		|	END AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	UNDEFINED AS OrderToShip,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	#TabPart AS TabPart
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = TabPart.Products
		|WHERE
		|	TabPart.Ref = &Ref
		|		AND TabPart.Count <> 0
		|		AND NOT (TabPart.ReadyToShip
		|				AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship))
		|		AND AllProducts.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage),
		|				VALUE(Enum.ItemsTypes.Work_5))";
	
	If IgnoreReadinessToProvide Then
	
		QueryTextOperations = StrReplace(QueryTextOperations, "TabPart.ReadyForSupply", "TRUE");
	
	EndIf;
	
	QueryTextsOfDocumentTables = New Structure;
	QueryTextsOfDocumentTables.Insert("TabPart", QueryTextTabPart);
	DocumentsPosting.PrepareRequestTextForDocument(QueryTextOperations, QueryTextsOfDocumentTables);
	
	Return QueryTextOperations;
	
EndFunction

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// procedures and functions serving the Accumulation register of need reserves

Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Set = Document.RegisterRecords.InventoryAndDemands;
	
	If Set.DataExchange.Load Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager; // there is a temporary table of changes to the Register of Documents.
	
	// For a new document, the calculation is already going on for all the records of the set, since they are all in the set changes table.
	QueuePositionChanged =
		Metadata.DefinedTypes.ExpectedShipment.Type.ContainsType(TypeOf(Set.Filter.Recorder.Value))
		And Set.AdditionalProperties.Property("DocumentProperties") // during batch stages, document properties may not be initialized.
		And Set.AdditionalProperties.DocumentProperties.WriteMode = DocumentWriteMode.Posting
		And Not Set.AdditionalProperties.DocumentProperties.IsNew
		And QueuePositionChanged(Query);
		
	If QueuePositionChanged Then
		Document.AdditionalProperties.Insert("PlaceInInventoryDistributionQueueHasChanged", True);
	EndIf;
	
EndProcedure

Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Return; // no additional actions are provided in the current configuration
	
EndProcedure

Function QueryTextOfInitialRegisteredRecordedInventoryAndNeeds(CheckLoggerAndActivity = True, CheckNewOne = True) Export
	
	Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS OrderDocument,
		|	Table.OrderToShip AS OrderToShip,
		|	Table.EventDate AS EventDate,
		|	Table.ReversingEntry AS ReversingEntry,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.InStock
		|		ELSE -Table.InStock
		|	END AS InStock,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.Received_1
		|		ELSE -Table.Received_1
		|	END AS Received_1,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.Ordered
		|		ELSE -Table.Ordered
		|	END AS Ordered,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.ReserveAtWarehouse
		|		ELSE -Table.ReserveAtWarehouse
		|	END AS ReserveAtWarehouse,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.ReserveAsReceived
		|		ELSE -Table.ReserveAsReceived
		|	END AS ReserveAsReceived,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.SnoozeReservation
		|		ELSE -Table.SnoozeReservation
		|	END AS SnoozeReservation,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.ToSupply
		|		ELSE -Table.ToSupply
		|	END AS ToSupply,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.NotProvide
		|		ELSE -Table.NotProvide
		|	END AS NotProvide,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.LockedInStock
		|		ELSE -Table.LockedInStock
		|	END AS LockedInStock,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.LockedReceipt
		|		ELSE -Table.LockedReceipt
		|	END AS LockedReceipt,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.ToUnlock
		|		ELSE -Table.ToUnlock
		|	END AS ToUnlock,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.ReserveAtWarehouseFromLocked
		|		ELSE -Table.ReserveAtWarehouseFromLocked
		|	END AS ReserveAtWarehouseFromLocked,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.ReserveUponReceiptFromLocked
		|		ELSE -Table.ReserveUponReceiptFromLocked
		|	END AS ReserveUponReceiptFromLocked,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.CloseReceiptSchedule
		|		ELSE -Table.CloseReceiptSchedule
		|	END AS CloseReceiptSchedule,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) AND Table.ToControlQuality
		|			THEN Table.CloseReceiptSchedule
		|		WHEN Table.ToControlQuality
		|			THEN -Table.CloseReceiptSchedule
		|		ELSE 0
		|	END AS CloseReceiptScheduleCheckQuality,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) AND Table.SubjectToUnlocking
		|			THEN Table.CloseReceiptSchedule
		|		WHEN Table.SubjectToUnlocking
		|			THEN -Table.CloseReceiptSchedule
		|		ELSE 0
		|	END AS CloseReceiptScheduleToBeUnblocked,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.CloseScheduleShipping
		|		ELSE -Table.CloseScheduleShipping
		|	END AS CloseScheduleShipping,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN Table.InStock
		|		ELSE 0
		|	END AS InStockExpense,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN Table.LockedInStock
		|		ELSE 0
		|	END AS LockedInStockExpense,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.InStock
		|		ELSE 0
		|	END AS InStockReceipt,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.InStock
		|		ELSE -Table.InStock
		|	END AS AvailableMinusBlocked,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.Received_1
		|		ELSE -Table.Received_1
		|	END AS YouWillReceiveNegativeMessageBlocked,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN Table.InStock
		|		ELSE 0
		|	END AS AvailableExpenseMinusBlocked
		|INTO InventoryAndDemandsBeforeWrite
		|FROM
		|	AccumulationRegister.InventoryAndDemands AS Table
		|WHERE
		|	Table.Recorder IN(&Recorder)
		|		AND NOT &IsNew
		|		AND Table.Active";
	If Not CheckLoggerAndActivity Then
		Text = StrReplace(Text, "Table.Recorder IN(&Recorder)", "TRUE");
		Text = StrReplace(Text, "Table.Active", "TRUE");
	EndIf;
	If Not CheckNewOne Then
		Text = StrReplace(Text, "&IsNew", "FALSE");
	EndIf;
	
	If GetFunctionalOption("UseGoodsQualityControl") Then
		
		Texts = New Array();
		Text = StrReplace(Text, "InventoryAndDemandsBeforeWrite", "InventoryAndNeedsBeforeRecordingPreliminary");
		Texts.Add(Text);
		
		Text =
			"SELECT
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Warehouse AS Warehouse,
			|	Set.Purpose AS Purpose,
			|	Set.OrderDocument AS OrderDocument,
			|	Set.OrderToShip AS OrderToShip,
			|	Set.EventDate AS EventDate,
			|	Set.ReversingEntry AS ReversingEntry,
			|	SUM(Set.InStock) AS InStock,
			|	SUM(Set.BlockedInStockSummary) AS BlockedInStockSummary,
			|	SUM(Set.Received_1) AS Received_1,
			|	SUM(Set.Ordered) AS Ordered,
			|	SUM(Set.ReserveAtWarehouse) AS ReserveAtWarehouse,
			|	SUM(Set.ReserveAsReceived) AS ReserveAsReceived,
			|	SUM(Set.SnoozeReservation) AS SnoozeReservation,
			|	SUM(Set.ToSupply) AS ToSupply,
			|	SUM(Set.NotProvide) AS NotProvide,
			|	SUM(Set.LockedInStock) AS LockedInStock,
			|	SUM(Set.LockedReceipt) AS LockedReceipt,
			|	SUM(Set.ToUnlock) AS ToUnlock,
			|	SUM(Set.ReserveAtWarehouseFromLocked) AS ReserveAtWarehouseFromLocked,
			|	SUM(Set.ReserveUponReceiptFromLocked) AS ReserveUponReceiptFromLocked,
			|	SUM(Set.CloseReceiptSchedule) AS CloseReceiptSchedule,
			|	SUM(Set.CloseReceiptScheduleCheckQuality) AS CloseReceiptScheduleCheckQuality,
			|	SUM(Set.CloseReceiptScheduleToBeUnblocked) AS CloseReceiptScheduleToBeUnblocked,
			|	SUM(Set.CloseScheduleShipping) AS CloseScheduleShipping,
			|	SUM(Set.InStockExpense) AS InStockExpense,
			|	SUM(Set.LockedInStockExpense) AS LockedInStockExpense,
			|	SUM(Set.InStockReceipt) AS InStockReceipt,
			|	
			|	CASE
			|		WHEN SUM(Set.InStock) > 0
			|				AND SUM(Set.InStock) < SUM(Set.BlockedInStockSummary)
			|			THEN 0
			|		WHEN SUM(Set.InStock) > 0
			|				AND SUM(Set.BlockedInStockSummary) > 0
			|			THEN
			|				SUM(Set.InStock) - SUM(Set.BlockedInStockSummary)
			|		WHEN SUM(Set.InStock) < 0
			|				AND SUM(Set.InStock) > SUM(Set.BlockedInStockSummary)
			|			THEN 0
			|		WHEN SUM(Set.InStock) < 0
			|				AND SUM(Set.BlockedInStockSummary) < 0
			|			THEN SUM(Set.InStock) - SUM(Set.BlockedInStockSummary)
			|		ELSE SUM(Set.InStock)
			|	END AS AvailableMinusBlocked,
			|	
			|	CASE
			|		WHEN SUM(Set.Received_1) > 0
			|				AND SUM(Set.Received_1) < SUM(Set.LockedReceipt)
			|			THEN 0
			|		WHEN SUM(Set.Received_1) > 0
			|				AND SUM(Set.LockedReceipt) > 0
			|			THEN
			|				SUM(Set.Received_1) - SUM(Set.LockedReceipt)
			|		WHEN SUM(Set.Received_1) < 0
			|				AND SUM(Set.Received_1) > SUM(Set.LockedReceipt)
			|			THEN 0
			|		WHEN SUM(Set.Received_1) < 0
			|				AND SUM(Set.LockedReceipt) < 0
			|			THEN SUM(Set.Received_1) - SUM(Set.LockedReceipt)
			|		ELSE SUM(Set.Received_1)
			|	END AS YouWillReceiveNegativeMessageBlocked,
			|	
			|	CASE
			|		WHEN SUM(Set.InStockExpense) > 0
			|				AND SUM(Set.InStockExpense) < SUM(Set.BlockedInStockExpenseSummary)
			|			THEN 0
			|		WHEN SUM(Set.InStockExpense) > 0
			|				AND SUM(Set.BlockedInStockExpenseSummary) > 0
			|			THEN
			|				SUM(Set.InStockExpense) - SUM(Set.BlockedInStockExpenseSummary)
			|		WHEN SUM(Set.InStockExpense) < 0
			|				AND SUM(Set.InStockExpense) > SUM(Set.BlockedInStockExpenseSummary)
			|			THEN 0
			|		WHEN SUM(Set.InStockExpense) < 0
			|				AND SUM(Set.BlockedInStockExpenseSummary) < 0
			|			THEN SUM(Set.InStockExpense) - SUM(Set.BlockedInStockExpenseSummary)
			|		ELSE SUM(Set.InStockExpense)
			|	END AS AvailableExpenseMinusBlocked
			|	
			|INTO InventoryAndDemandsBeforeWrite
			|FROM(
			|	SELECT
			|		Table.Products AS Products,
			|		Table.Characteristic AS Characteristic,
			|		Table.Warehouse AS Warehouse,
			|		Table.Purpose AS Purpose,
			|		Table.OrderDocument AS OrderDocument,
			|		Table.OrderToShip AS OrderToShip,
			|		Table.EventDate AS EventDate,
			|		Table.ReversingEntry AS ReversingEntry,
			|		Table.InStock AS InStock,
			|		Table.Received_1 AS Received_1,
			|		Table.Ordered AS Ordered,
			|		Table.ReserveAtWarehouse AS ReserveAtWarehouse,
			|		Table.ReserveAsReceived AS ReserveAsReceived,
			|		Table.SnoozeReservation AS SnoozeReservation,
			|		Table.ToSupply AS ToSupply,
			|		Table.NotProvide AS NotProvide,
			|		Table.LockedInStock AS LockedInStock,
			|		Table.LockedReceipt AS LockedReceipt,
			|		Table.ToUnlock AS ToUnlock,
			|		Table.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
			|		Table.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			|		Table.CloseReceiptSchedule AS CloseReceiptSchedule,
			|		Table.CloseReceiptScheduleCheckQuality AS CloseReceiptScheduleCheckQuality,
			|		Table.CloseReceiptScheduleToBeUnblocked AS CloseReceiptScheduleToBeUnblocked,
			|		Table.CloseScheduleShipping AS CloseScheduleShipping,
			|		Table.InStockExpense AS InStockExpense,
			|		Table.LockedInStockExpense AS LockedInStockExpense,
			|		Table.InStockReceipt AS InStockReceipt,
			|		0 AS BlockedInStockSummary,
			|		0 AS BlockedInStockExpenseSummary
			|	FROM
			|		InventoryAndNeedsBeforeRecordingPreliminary AS Table
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		Table.Products AS Products,
			|		Table.Characteristic AS Characteristic,
			|		Table.Warehouse AS Warehouse,
			|		Table.Purpose AS Purpose,
			|		UNDEFINED AS OrderDocument,
			|		Table.OrderToShip AS OrderToShip,
			|		Table.EventDate AS EventDate,
			|		Table.ReversingEntry AS ReversingEntry,
			|		0 AS InStock,
			|		0 AS Received_1,
			|		0 AS Ordered,
			|		0 AS ReserveAtWarehouse,
			|		0 AS ReserveAsReceived,
			|		0 AS SnoozeReservation,
			|		0 AS ToSupply,
			|		0 AS NotProvide,
			|		0 AS LockedInStock,
			|		0 AS LockedReceipt,
			|		0 AS ToUnlock,
			|		0 AS ReserveAtWarehouseFromLocked,
			|		0 AS ReserveUponReceiptFromLocked,
			|		0 AS CloseReceiptSchedule,
			|		0 AS CloseReceiptScheduleCheckQuality,
			|		0 AS CloseReceiptScheduleToBeUnblocked,
			|		0 AS CloseScheduleShipping,
			|		0 AS InStockExpense,
			|		0 AS LockedInStockExpense,
			|		0 AS InStockReceipt,
			|		Table.LockedInStock AS BlockedInStockSummary,
			|		Table.LockedInStockExpense AS BlockedInStockExpenseSummary
			|	FROM
			|		InventoryAndNeedsBeforeRecordingPreliminary AS Table) AS Set
			|GROUP BY
			|	Set.Products,
			|	Set.Characteristic,
			|	Set.Warehouse,
			|	Set.Purpose,
			|	Set.OrderDocument,
			|	Set.OrderToShip,
			|	Set.EventDate,
			|	Set.ReversingEntry";
		
		Texts.Add(Text);
		Texts.Add("DROP InventoryAndNeedsBeforeRecordingPreliminary");
		Text = StrConcat(Texts, Common.QueryBatchSeparator());
		
	EndIf;
	
	Return Text;
	
EndFunction

Function QueryTextOfChangesInRegisteredRecordedInventoryAndNeeds(CheckLoggerAndActivity, TableName = Undefined) Export
	
	Texts = New Array();
	
	Text = QueryTextOfInitialRegisteredRecordedInventoryAndNeeds(CheckLoggerAndActivity, False);
	Text = StrReplace(Text, "InventoryAndDemandsBeforeWrite", "InventoryAndRecordingRequirements");
	If TableName <> Undefined Then
		Text = StrReplace(Text, "AccumulationRegister.InventoryAndDemands", TableName);
	EndIf;
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	ChangesTable.Products AS Products,
		|	ChangesTable.Characteristic AS Characteristic,
		|	ChangesTable.Warehouse AS Warehouse,
		|	ChangesTable.Purpose AS Purpose,
		|	ChangesTable.OrderDocument AS OrderDocument,
		|	ChangesTable.EventDate AS EventDate,
		|	MAX(ChangesTable.DirectionOfActivityFromDestination) AS DirectionOfActivityFromDestination,
		|	MAX(ChangesTable.OrderingFromDestination) AS OrderingFromDestination,
		|	MAX(ChangesTable.PartnerFromDestination) AS PartnerFromDestination,
		|	MAX(CASE
		|		WHEN ChangesTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			THEN FALSE
		|		WHEN VALUETYPE(ChangesTable.OrderingFromDestination) IN(
		|				TYPE(Document.MaterialProviderOrder2_5))
		|			THEN FALSE
		|		WHEN ChangesTable.PartnerFromDestination <> VALUE(Catalog.Partners.EmptyRef)
		|			AND ChangesTable.OrderingFromDestination = UNDEFINED
		|			THEN FALSE
		|		WHEN ChangesTable.DirectionOfActivityFromDestination <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|			AND ChangesTable.OrderingFromDestination = UNDEFINED
		|			THEN NOT ChangesTable.ControlOnlyStock
		|		WHEN &ControlExcessOfSeparateProvision AND ChangesTable.OrderingFromDestination <> UNDEFINED
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS ControlExcessOfSeparateProvision,
		|	SUM(ChangesTable.InStock) AS InStock,
		|	SUM(ChangesTable.Received_1) AS Received_1,
		|	SUM(ChangesTable.Ordered) AS Ordered,
		|	SUM(ChangesTable.ReserveAtWarehouse) AS ReserveAtWarehouse,
		|	SUM(ChangesTable.ReserveAsReceived) AS ReserveAsReceived,
		|	SUM(ChangesTable.SnoozeReservation) AS SnoozeReservation,
		|	SUM(ChangesTable.ToSupply) AS ToSupply,
		|	SUM(ChangesTable.NotProvide) AS NotProvide,
		|	SUM(ChangesTable.LockedInStock) AS LockedInStock,
		|	SUM(ChangesTable.LockedReceipt) AS LockedReceipt,
		|	SUM(ChangesTable.ToUnlock) AS ToUnlock,
		|	SUM(ChangesTable.ReserveAtWarehouseFromLocked) AS ReserveAtWarehouseFromLocked,
		|	SUM(ChangesTable.ReserveUponReceiptFromLocked) AS ReserveUponReceiptFromLocked,
		|	SUM(ChangesTable.CloseReceiptSchedule) AS CloseReceiptSchedule,
		|	SUM(ChangesTable.CloseReceiptScheduleCheckQuality) AS CloseReceiptScheduleCheckQuality,
		|	SUM(ChangesTable.CloseReceiptScheduleToBeUnblocked) AS CloseReceiptScheduleToBeUnblocked,
		|	SUM(ChangesTable.CloseScheduleShipping) AS CloseScheduleShipping,
		|	SUM(ChangesTable.InStockExpense) AS InStockExpense,
		|	SUM(ChangesTable.LockedInStockExpense) AS LockedInStockExpense,
		|	SUM(ChangesTable.InStockReceipt) AS InStockReceipt,
		|	SUM(ChangesTable.AvailableMinusBlocked) AS AvailableMinusBlocked,
		|	SUM(ChangesTable.YouWillReceiveNegativeMessageBlocked) AS YouWillReceiveNegativeMessageBlocked,
		|	SUM(ChangesTable.AvailableExpenseMinusBlocked) AS AvailableExpenseMinusBlocked
		|INTO InventoryAndDemandsUpdate
		|FROM(
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		CAST(Table.Purpose AS Catalog.Assignments).LineOfBusiness AS DirectionOfActivityFromDestination,
		|		CAST(Table.Purpose AS Catalog.Assignments).OrderDocument AS OrderingFromDestination,
		|		CAST(Table.Purpose AS Catalog.Assignments).Partner AS PartnerFromDestination,
		|		CAST(Table.Purpose AS Catalog.Assignments).ControlOnlyStock AS ControlOnlyStock,
		|		CASE
		|			WHEN Table.OrderDocument = UNDEFINED
		|				THEN Table.OrderToShip
		|			ELSE Table.OrderDocument
		|		END AS OrderDocument,
		|		Table.EventDate AS EventDate,
		|		Table.InStock AS InStock,
		|		Table.Received_1 AS Received_1,
		|		Table.Ordered AS Ordered,
		|		Table.ReserveAtWarehouse AS ReserveAtWarehouse,
		|		Table.ReserveAsReceived AS ReserveAsReceived,
		|		Table.SnoozeReservation AS SnoozeReservation,
		|		Table.ToSupply AS ToSupply,
		|		Table.NotProvide AS NotProvide,
		|		Table.LockedInStock AS LockedInStock,
		|		Table.LockedReceipt AS LockedReceipt,
		|		Table.ToUnlock AS ToUnlock,
		|		Table.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
		|		Table.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
		|		Table.CloseReceiptSchedule AS CloseReceiptSchedule,
		|		Table.CloseReceiptScheduleCheckQuality AS CloseReceiptScheduleCheckQuality,
		|		Table.CloseReceiptScheduleToBeUnblocked AS CloseReceiptScheduleToBeUnblocked,
		|		Table.CloseScheduleShipping AS CloseScheduleShipping,
		|		Table.InStockExpense AS InStockExpense,
		|		Table.LockedInStockExpense AS LockedInStockExpense,
		|		Table.InStockReceipt AS InStockReceipt,
		|		Table.AvailableMinusBlocked AS AvailableMinusBlocked,
		|		Table.YouWillReceiveNegativeMessageBlocked AS YouWillReceiveNegativeMessageBlocked,
		|		Table.AvailableExpenseMinusBlocked AS AvailableExpenseMinusBlocked
		|	FROM
		|		InventoryAndRecordingRequirements AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		CAST(Table.Purpose AS Catalog.Assignments).LineOfBusiness AS DirectionOfActivityFromDestination,
		|		CAST(Table.Purpose AS Catalog.Assignments).OrderDocument AS OrderingFromDestination,
		|		CAST(Table.Purpose AS Catalog.Assignments).Partner AS PartnerFromDestination,
		|		CAST(Table.Purpose AS Catalog.Assignments).ControlOnlyStock AS ControlOnlyStock,
		|		CASE
		|			WHEN Table.OrderDocument = UNDEFINED
		|				THEN Table.OrderToShip
		|			ELSE Table.OrderDocument
		|		END AS OrderDocument,
		|		Table.EventDate AS EventDate,
		|		-Table.InStock AS InStock,
		|		-Table.Received_1 AS Received_1,
		|		-Table.Ordered AS Ordered,
		|		-Table.ReserveAtWarehouse AS ReserveAtWarehouse,
		|		-Table.ReserveAsReceived AS ReserveAsReceived,
		|		-Table.SnoozeReservation AS SnoozeReservation,
		|		-Table.ToSupply AS ToSupply,
		|		-Table.NotProvide AS NotProvide,
		|		-Table.LockedInStock AS LockedInStock,
		|		-Table.LockedReceipt AS LockedReceipt,
		|		-Table.ToUnlock AS ToUnlock,
		|		-Table.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
		|		-Table.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
		|		-Table.CloseReceiptSchedule AS CloseReceiptSchedule,
		|		-Table.CloseReceiptScheduleCheckQuality AS CloseReceiptScheduleCheckQuality,
		|		-Table.CloseReceiptScheduleToBeUnblocked AS CloseReceiptScheduleToBeUnblocked,
		|		-Table.CloseScheduleShipping AS CloseScheduleShipping,
		|		-Table.InStockExpense AS InStockExpense,
		|		-Table.LockedInStockExpense AS LockedInStockExpense,
		|		-Table.InStockReceipt AS InStockReceipt,
		|		-Table.AvailableMinusBlocked AS AvailableMinusBlocked,
		|		-Table.YouWillReceiveNegativeMessageBlocked AS YouWillReceiveNegativeMessageBlocked,
		|		-Table.AvailableExpenseMinusBlocked AS AvailableExpenseMinusBlocked
		|	FROM
		|		InventoryAndDemandsBeforeWrite AS Table) AS ChangesTable
		|GROUP BY
		|	ChangesTable.Products,
		|	ChangesTable.Characteristic,
		|	ChangesTable.Warehouse,
		|	ChangesTable.Purpose,
		|	ChangesTable.OrderDocument,
		|	ChangesTable.EventDate
		|HAVING
		|	SUM(ChangesTable.InStock) <> 0
		|		OR SUM(ChangesTable.Received_1) <> 0
		|		OR SUM(ChangesTable.Ordered) <> 0
		|		OR SUM(ChangesTable.ReserveAtWarehouse) <> 0
		|		OR SUM(ChangesTable.ReserveAsReceived) <> 0
		|		OR SUM(ChangesTable.SnoozeReservation) <> 0
		|		OR SUM(ChangesTable.ToSupply) <> 0
		|		OR SUM(ChangesTable.NotProvide) <> 0
		|		OR SUM(ChangesTable.LockedInStock) <> 0
		|		OR SUM(ChangesTable.LockedReceipt) <> 0
		|		OR SUM(ChangesTable.ToUnlock) <> 0
		|		OR SUM(ChangesTable.ReserveAtWarehouseFromLocked) <> 0
		|		OR SUM(ChangesTable.ReserveUponReceiptFromLocked) <> 0
		|		OR SUM(ChangesTable.CloseReceiptSchedule) <> 0
		|		OR SUM(ChangesTable.CloseReceiptScheduleCheckQuality) <> 0
		|		OR SUM(ChangesTable.CloseReceiptScheduleToBeUnblocked) <> 0
		|		OR SUM(ChangesTable.CloseScheduleShipping) <> 0
		|		OR SUM(ChangesTable.InStockExpense) <> 0
		|		OR SUM(ChangesTable.LockedInStockExpense) <> 0
		|		OR SUM(ChangesTable.InStockReceipt) <> 0
		|		OR SUM(ChangesTable.AvailableMinusBlocked) <> 0
		|		OR SUM(ChangesTable.YouWillReceiveNegativeMessageBlocked) <> 0
		|		OR SUM(ChangesTable.AvailableExpenseMinusBlocked) <> 0";
		
	Texts.Add(Text);
	Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Return Text;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for batch work with the Inventory Allocation data register

////////////////////////////////////////////////////////////////////////////////
// Utilities

// Parameters:
//  Table - ValueTable - the table to add columns to.
Procedure AddRegisterColumns(Table) Export
	
	RegisterTable = AccumulationRegisters.InventoryAndDemands.CreateRecordSet().UnloadColumns(
		"Recorder,CloseScheduleShipping,CloseReceiptSchedule,ReversingEntry");
	If Table.Columns.Find("Recorder") = Undefined Then
		Table.Columns.Add("Recorder", RegisterTable.Columns.Recorder.ValueType);
	EndIf;
	If Table.Columns.Find("CloseScheduleShipping") = Undefined Then
		Table.Columns.Add("CloseScheduleShipping", RegisterTable.Columns.CloseScheduleShipping.ValueType);
	EndIf;
	If Table.Columns.Find("CloseReceiptSchedule") = Undefined Then
		Table.Columns.Add("CloseReceiptSchedule", RegisterTable.Columns.CloseReceiptSchedule.ValueType);
	EndIf;
	If Table.Columns.Find("ReversingEntry") = Undefined Then
		Table.Columns.Add("ReversingEntry", RegisterTable.Columns.ReversingEntry.ValueType);
	EndIf;
	
EndProcedure

// Returns:
//  Structure - structure with fields:
//   * TypesOfExpectedAdmission - Array of Type -
Function ParameterValuesForQueryTextsAndDocuments() Export
	
	ParameterValues = New Structure;
	ParameterValues.Insert("TypesOfExpectedAdmission",
		Metadata.DefinedTypes.ExpectedReceipt.Type.Types());
	
	Return ParameterValues;
	
EndFunction

Procedure ReflectInventoryAllocationTasks(Document, TempTablesManager) Export
	
	If TempTablesManager.Tables.Find("InventoryAndDemandsUpdate") = Undefined
			Or Document.AdditionalProperties.Property("BlockInventoryAllocation")
				And Document.AdditionalProperties.BlockInventoryAllocation Then
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("StockAllocationRecords.ReflectInventoryAllocationTasks");
	
	If InventoryAllocation.CountRegisterWithRoutineTask() Then
		
		Text =
			"SELECT DISTINCT
			|	MovementChanges.Products AS Products,
			|	MovementChanges.Characteristic AS Characteristic,
			|	MovementChanges.Warehouse AS Warehouse,
			|	MovementChanges.Purpose AS Purpose,
			|	UNDEFINED AS ShipmentOrder,
			|	0 AS ToReserveRemoval,
			|	0 AS ToReserveRemovalFromUnlocked
			|FROM
			|	InventoryAndDemandsUpdate AS MovementChanges
			|WHERE
			|	NOT VALUETYPE(MovementChanges.OrderDocument) IN(&TypesExpectedShipment)
			|
			|UNION ALL
			|
			|SELECT
			|	MovementChanges.Products AS Products,
			|	MovementChanges.Characteristic AS Characteristic,
			|	MovementChanges.Warehouse AS Warehouse,
			|	MovementChanges.Purpose AS Purpose,
			|	MovementChanges.OrderDocument AS ShipmentOrder,
			|	CASE
			|		WHEN SUM(MovementChanges.InStockExpense + MovementChanges.ReserveAtWarehouse) > 0
			|			THEN SUM(MovementChanges.InStockExpense + MovementChanges.ReserveAtWarehouse)
			|		ELSE 0
			|	END AS ToReserveRemoval,
			|	CASE
			|		WHEN SUM(MovementChanges.LockedInStockExpense + MovementChanges.ReserveAtWarehouseFromLocked) > 0
			|			THEN SUM(MovementChanges.LockedInStockExpense + MovementChanges.ReserveAtWarehouseFromLocked)
			|		ELSE 0
			|	END AS ToReserveRemovalFromUnlocked
			|FROM
			|	InventoryAndDemandsUpdate AS MovementChanges
			|WHERE
			|	VALUETYPE(MovementChanges.OrderDocument) IN(&TypesExpectedShipment)
			|GROUP BY
			|	MovementChanges.Products,
			|	MovementChanges.Characteristic,
			|	MovementChanges.Warehouse,
			|	MovementChanges.Purpose,
			|	MovementChanges.OrderDocument";
		
		If Document.Ref <> Undefined And Document.AdditionalProperties.Property("PlaceInInventoryDistributionQueueHasChanged") Then
			
			QueriesTexts = New Array();
			QueriesTexts.Add(Text);
			
			Text =
				"SELECT DISTINCT
				|	RegisterRecords.Products AS Products,
				|	RegisterRecords.Characteristic AS Characteristic,
				|	RegisterRecords.Warehouse AS Warehouse,
				|	RegisterRecords.Purpose AS Purpose,
				|	RegisterRecords.OrderDocument AS ShipmentOrder,
				|	0 AS ToReserveRemoval,
				|	0 AS ToReserveRemovalFromUnlocked
				|FROM
				|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
				|WHERE
				|	RegisterRecords.Recorder = &Recorder
				|		AND RegisterRecords.Active";
				
			QueriesTexts.Add(Text);
			TheTextOfASubquery = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
			Text =
				"SELECT
				|	Set.Products AS Products,
				|	Set.Characteristic AS Characteristic,
				|	Set.Warehouse AS Warehouse,
				|	Set.Purpose AS Purpose,
				|	Set.ShipmentOrder AS ShipmentOrder,
				|	MAX(Set.ToReserveRemoval) AS ToReserveRemoval,
				|	MAX(Set.ToReserveRemovalFromUnlocked) AS ToReserveRemovalFromUnlocked
				|FROM
				|	TheTextOfASubquery AS Set
				|GROUP BY
				|	Set.Products,
				|	Set.Characteristic,
				|	Set.Warehouse,
				|	Set.Purpose,
				|	Set.ShipmentOrder";
			Text = StrReplace(Text, "TheTextOfASubquery", StrTemplate("(%1)", TheTextOfASubquery));
			
		EndIf;
		
		Query = New Query();
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("Recorder", Document.Ref);
		Query.Text = Text;
		Query.SetParameter("TypesExpectedShipment", Metadata.DefinedTypes.ExpectedShipment.Type.Types());
		
		Table = Query.Execute().Unload();
		Table.Columns.Add("RecordDate");
		Table.FillValues(CurrentUniversalDate(), "RecordDate");
		OrderStructureCalculationQueue = 0;
		If Document.AdditionalProperties.Property("OrderStructureCalculationQueue", OrderStructureCalculationQueue) Then
			Table.Columns.Add("OrderStructureCalculationQueue");
			Table.FillValues(OrderStructureCalculationQueue, "OrderStructureCalculationQueue");
		EndIf;
		DeferredJobs.ProcessQueueTasks("JobsForAllocatingInventory", Table);
		
	Else
		
		Text =
			"SELECT DISTINCT
			|	MovementChanges.Products AS Products,
			|	MovementChanges.Characteristic AS Characteristic,
			|	MovementChanges.Warehouse AS Warehouse,
			|	MovementChanges.Purpose AS Purpose
			|INTO InventoryDistributionProducts
			|FROM
			|	InventoryAndDemandsUpdate AS MovementChanges
			|INDEX BY
			|	Products,Characteristic,Warehouse,Purpose";
		
		If Document.Ref <> Undefined And Document.AdditionalProperties.Property("PlaceInInventoryDistributionQueueHasChanged") Then
			
			Text =
				"SELECT DISTINCT
				|	MovementChanges.Products AS Products,
				|	MovementChanges.Characteristic AS Characteristic,
				|	MovementChanges.Warehouse AS Warehouse,
				|	MovementChanges.Purpose AS Purpose
				|INTO InventoryDistributionProducts
				|FROM
				|	InventoryAndDemandsUpdate AS MovementChanges
				|
				|UNION
				|
				|SELECT DISTINCT
				|	RegisterRecords.Products AS Products,
				|	RegisterRecords.Characteristic AS Characteristic,
				|	RegisterRecords.Warehouse AS Warehouse,
				|	RegisterRecords.Purpose AS Purpose
				|FROM
				|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
				|WHERE
				|	RegisterRecords.Recorder = &Recorder
				|		AND RegisterRecords.Active
				|INDEX BY
				|	Products,Characteristic,Warehouse,Purpose";
				
		EndIf;
		
		Query = New Query();
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("Recorder", Document.Ref);
		Query.Text = Text;
		Query.Execute();
		
		RequestingStates = New Query();
		RequestingStates.TempTablesManager =  TempTablesManager;
		InventoryAllocation.AddTemporaryStateUpdateTables(RequestingStates, "InventoryDistributionProducts", "BeforeWrite");
		
		Query.Text =
			"SELECT
			|	MovementChanges.Products AS Products,
			|	MovementChanges.Characteristic AS Characteristic,
			|	MovementChanges.Warehouse AS Warehouse,
			|	MovementChanges.Purpose AS Purpose,
			|	MovementChanges.OrderDocument AS ShipmentOrder,
			|	SUM(MovementChanges.InStockExpense + MovementChanges.ReserveAtWarehouse) AS Shipment
			|INTO ChangingBalanceOfGoodsToControlBalance
			|FROM
			|	InventoryAndDemandsUpdate AS MovementChanges
			|GROUP BY
			|	MovementChanges.Products,
			|	MovementChanges.Characteristic,
			|	MovementChanges.Warehouse,
			|	MovementChanges.Purpose,
			|	MovementChanges.OrderDocument
			|HAVING
			|	SUM(MovementChanges.InStockExpense + MovementChanges.ReserveAtWarehouse) > 0
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, OrderDocument";
		Query.Execute();
		InventoryAllocation.RecordDistributionOfStocksInTransaction(Query);
		Query.Text = "DROP ChangingBalanceOfGoodsToControlBalance";
		Query.Execute();
		
		InventoryAllocation.AddTemporaryStateUpdateTables(RequestingStates, "InventoryDistributionProducts", "OnWrite");
		InventoryAllocation.TableOfChangesStockAllocationForStateCalculation(RequestingStates);
		
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

#EndRegion

#Region Private

Procedure AddEmptyBalanceChangeTableForItemsToControlBalances(Query) Export
	
	Query.Text =
		"SELECT
		|	NULL AS Products,
		|	NULL AS Characteristic,
		|	NULL AS Warehouse,
		|	NULL AS Purpose,
		|	NULL AS ShipmentOrder,
		|	0 AS Shipment
		|INTO ChangingBalanceOfGoodsToControlBalance
		|WHERE
		|	FALSE";
	Query.Execute();
	
EndProcedure

Function ReflectionTemplateTexts(Registers, QueryTextOperations, RegisterName)
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		ReflectionTemplateTexts.Insert(RegisterName, QueryTextOperations);
	EndIf;
	Return ReflectionTemplateTexts;
	
EndFunction

Function QueuePositionChanged(Query)
	
	Result = False;
	If Query.TempTablesManager.Tables.Find("RegisterOfDocumentsChanges") <> Undefined Then
		
		Query.Text =
			"SELECT TOP 1
			|	TRUE AS QueuePositionChanged
			|FROM
			|	RegisterOfDocumentsChanges AS Table
			|WHERE
			|	NOT Table.AdditionalEntryBeforeChange
			|		OR NOT Table.AdditionalRecord
			|GROUP BY
			|	Table.Ref
			|HAVING
			|	NOT MAX(Table.PriorityBeforeChange) IS NULL
			|		AND NOT MAX(Table.Priority) IS NULL
			|		AND (MAX(Table.PriorityBeforeChange) <> MAX(Table.Priority)
			|			OR MAX(Table.IBDocumentDate) <> MIN(Table.IBDocumentDate))";
		Result = Not Query.Execute().IsEmpty();
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
