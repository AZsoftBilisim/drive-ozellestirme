
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#If Not MobileStandaloneServer Then

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("GoodsDelivery");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.GoodsIssueNote") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	ElsIf TypeOf(Document) = Type("DocumentRef.GoodsIssueNote") Then
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
	Else
		DocumentObject = Undefined;
		DocumentRef = Undefined;
	EndIf;

	Query = New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextDelivery(Query, QueryTexts, Registers, DocumentObject);
		
	EndIf;
	
	ShipGoodsFromWarehouse_(Query, QueryTexts, Registers, DocumentObject);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.GoodsPickingPlacement.AddGenerateCommand(GenerationCommands);
	
	Documents.DamageNote.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsMisgradingNote.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command to create the document "Expenditure order for goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsIssueNote) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsIssueNote.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsIssueNote);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseWarehouseManagemantSystemForGoodsIssue";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds the command to create the document "Expenditure order for goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsIssueNote) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateSpendingOrderForGoodsBasedOnIt";
		CreateBasedOnCommand.Id = "CreateSpendingOrderForGoodsBasedOnIt";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsIssueNote);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;		
		CreateBasedOnCommand.FunctionalOptions = "GoodsIssueNotesAreGeneratedByManager";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds the command to create the document "Expenditure order for goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddCommandToCreateSpendingOrderForGoodsBasedOnTransportationTask(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsIssueNote) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateSpendingOrderForGoodsBasedOnIt";
		CreateBasedOnCommand.Id = "CreateOnBasisOfSpendingOrderForGoodsOnTaskOfTransportation";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsIssueNote);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "GoodsIssueNotesAreGeneratedByManager";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#EndIf

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Premise,Status,WarehouseOperation,ReferenceOrder,DateOfShipment";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = New Structure;
	
	#If Not MobileStandaloneServer Then
		WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
		
		ShippedGoods = ProductsClientServer.SeriesSpecificationParameters();
		
		ShippedGoods.UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.DateOfShipment);  
	#Else
		WarehouseSeriesParameters = MobileWarehouseKeeperWorkspace.UseOfSeriesInStock(Object.Warehouse, False);
		
		ShippedGoods = MobileWarehouseKeeperWorkspace.ItemClientServerSerialSpecificationParameters();
		
		ShippedGoods.UseBinLocationWarehousing = MobileWarehouseKeeperWorkspace.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.DateOfShipment);
	#EndIf
	
	ShippedGoods.FullObjectName = "Document.GoodsIssueNote";
	ShippedGoods.ItSWarrant = True;
	
	ShippedGoods.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	ShippedGoods.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	ShippedGoods.ProductLocationsAreUsed = True;
	
	ShippedGoods.WarehouseTransactions.Add(Object.WarehouseOperation);
	
	ShippedGoods.NameTSGoods = "ShippedGoods";
	ShippedGoods.TSSeriesName = "ShippedGoods";
	ShippedGoods.FieldNameRoom = "Premise";
	
	If Object.Status = Enums.GoodsIssueNoteStatuses.Prepared Then
		
		ShippedGoods.OrderPreparation = True;
		ShippedGoods.ShipmentPlanning = False;
		ShippedGoods.SelectionPlanning = False;
		ShippedGoods.PickingCheck = False;
		ShippedGoods.FactOfSelection = False;
		
	ElsIf Object.Status = Enums.GoodsIssueNoteStatuses.ForPicking Then
		
		ShippedGoods.OrderPreparation = False;
		ShippedGoods.ShipmentPlanning = False;
		ShippedGoods.SelectionPlanning = True;
		ShippedGoods.PickingCheck = False;
		ShippedGoods.FactOfSelection = False;
		
	ElsIf Object.Status = Enums.GoodsIssueNoteStatuses.ForChecking Then	
		
		ShippedGoods.LinkFields.Add("Package");
		ShippedGoods.FieldNameQuantity = "NumberOfPackages";
		
		ShippedGoods.OrderPreparation = False;
		ShippedGoods.ShipmentPlanning = False;
		ShippedGoods.SelectionPlanning = False;
		ShippedGoods.PickingCheck = True;
		ShippedGoods.FactOfSelection = False;
		
	ElsIf Object.Status = Enums.GoodsIssueNoteStatuses.Verified
		Or Object.Status = Enums.GoodsIssueNoteStatuses.ToShip
		Or Object.Status = Enums.GoodsIssueNoteStatuses.Shipped_ Then
		
		ShippedGoods.LinkFields.Add("Package");
		ShippedGoods.FieldNameQuantity = "NumberOfPackages";
		
		ShippedGoods.OrderPreparation = False;
		ShippedGoods.ShipmentPlanning = False;
		ShippedGoods.SelectionPlanning = False;
		ShippedGoods.PickingCheck = False;
		ShippedGoods.FactOfSelection = True;
		
	EndIf;
	
	#If Not MobileStandaloneServer Then
		ShippedGoods.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(ShippedGoods);
	#Else
		ShippedGoods.RegisterSeries = MobileWarehouseKeeperWorkspace.ItIsNecessaryToRegisterSeries(ShippedGoods);
	#EndIf
	ShippedGoods.SpecialCheckingOfSeriesIndicationStatuses = True;
	
	ShippedGoods.LinkFields.Add("Action");
	ShippedGoods.LinkFields.Add("PackingListParent");
	ShippedGoods.LinkFields.Add("Purpose");
	
	ShippedGoods.ItSWarrant = True;
	ShippedGoods.FieldNameRoom = "Premise";
	ShippedGoods.FieldNameControlledLotReference = "ControlledLotReference";
	ShippedGoods.Date = Object.DateOfShipment;
	
	#If Not MobileStandaloneServer Then
		GoodsByReferences = ProductsClientServer.SeriesSpecificationParameters();
		GoodsByReferences.UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.DateOfShipment);
	#Else
		GoodsByReferences = MobileWarehouseKeeperWorkspace.ItemClientServerSerialSpecificationParameters();
		GoodsByReferences.UseBinLocationWarehousing = MobileWarehouseKeeperWorkspace.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.DateOfShipment);
	#EndIf
	
	GoodsByReferences.FullObjectName = "Document.GoodsIssueNote";
	GoodsByReferences.ThisIsAnInvoice = True;
	GoodsByReferences.ShipmentPlanning = True;
	
	GoodsByReferences.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	GoodsByReferences.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	GoodsByReferences.WarehouseTransactions.Add(Object.WarehouseOperation);
		
	GoodsByReferences.NameTSGoods = "GoodsByReferences";
	GoodsByReferences.TSSeriesName = "GoodsByReferences";
	GoodsByReferences.FieldNameRoom = "Premise";
	GoodsByReferences.FieldNameControlledLotReference = "ControlledLotReference";
	GoodsByReferences.FieldNameQuantity = "Count";
	GoodsByReferences.FieldNamesForOrderDefinition.Add("GoodsUnderOrders_Order");
	
	GoodsByReferences.LinkFields.Add("ReferenceOrder");
	GoodsByReferences.SpecialCheckingOfSeriesIndicationStatuses = False;
	
	SeriesSpecificationParameters.Insert("ShippedGoods", ShippedGoods);
	SeriesSpecificationParameters.Insert("GoodsByReferences", GoodsByReferences);
	
	Return SeriesSpecificationParameters;
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.NameTSGoods = "ShippedGoods" 
		Or SeriesSpecificationParameters.NameTSGoods = "SelectedLabeledProducts" Then
		QueryText = TextOfRequestForFillingInStatusesIndicatingSeriesOfProductsBeingShipped(SeriesSpecificationParameters);
	Else
		QueryText = TextOfRequestToFillInStatusesForSpecifyingProductSeriesByOrder(SeriesSpecificationParameters);
	EndIf;	
	
	Return QueryText;
	
EndFunction

#If Not MobileStandaloneServer Then

// Returns the value of the receipt or shipment order
//
// Parameters:
//  FieldValuesToIdentifyReferences	 - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - Link to the order.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	Return FieldValuesToIdentifyReferences.GoodsUnderOrders_Order;	
EndFunction

// Returns the request body for the get the available appointments
//	Parameters:
//		RequestFormationParameters - Structure - the parameters for the generation of text queries
//	Returns:
//		String - query text.
//
Function RequestTextForAvailableAssignments(RequestFormationParameters) Export
	
	QueryText = 
	"SELECT ALLOWED
	|	RegisterDataGoodsForShipment.Products,
	|	RegisterDataGoodsForShipment.Characteristic,
	|	SUM(RegisterDataGoodsForShipment.Demand) AS Demand,
	|	SUM(0) AS Supplied,
	|	Assignments.Ref AS Purpose,
	|	Assignments.RecordsInWarehouseRegisters AS RecordsInWarehouseRegisters,
	|	SUM(RegisterDataGoodsForShipment.Demand) - MAX(ISNULL(DocumentData.Count, 0)) AS Balance
	|FROM
	|	(SELECT
	|		GoodsForIssueBalance.Products AS Products,
	|		GoodsForIssueBalance.Characteristic AS Characteristic,
	|		GoodsForIssueBalance.Purpose AS Purpose,
	|		GoodsForIssueBalance.ToShipBalance AS Demand
	|	FROM
	|		AccumulationRegister.GoodsForIssue.Balance(
	|				,
	|				(&ByAllReferences OR DocumentShipments = &ReferenceOrder)
	|					AND (Products, Characteristic) IN (&FilterByGoods)
	|					AND Warehouse = &Warehouse
	|					AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)) AS GoodsForIssueBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForIssue.Products,
	|		GoodsForIssue.Characteristic,
	|		GoodsForIssue.Purpose,
	|		CASE
	|			WHEN GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 0
	|			ELSE GoodsForIssue.ToShip
	|		END
	|	FROM
	|		AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|	WHERE
	|		(GoodsForIssue.Products, GoodsForIssue.Characteristic) IN (&FilterByGoods)
	|		AND GoodsForIssue.Warehouse = &Warehouse
	|		AND GoodsForIssue.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|		AND GoodsForIssue.Recorder = &Recorder
	|		AND (&ByAllReferences OR GoodsForIssue.DocumentShipments = &ReferenceOrder)) AS RegisterDataGoodsForShipment
	|		LEFT JOIN GoodsOfDocumentAreGrouped AS DocumentData
	|		ON RegisterDataGoodsForShipment.Products = DocumentData.Products
	|			AND RegisterDataGoodsForShipment.Characteristic = DocumentData.Characteristic
	|			AND RegisterDataGoodsForShipment.Purpose = DocumentData.Purpose
	|		INNER JOIN Catalog.Assignments AS Assignments
	|		ON RegisterDataGoodsForShipment.Purpose = Assignments.Ref
	|WHERE
	|	RegisterDataGoodsForShipment.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	AND RegisterDataGoodsForShipment.Purpose.RecordsInWarehouseRegisters
	|
	|GROUP BY
	|	RegisterDataGoodsForShipment.Products,
	|	RegisterDataGoodsForShipment.Characteristic,
	|	Assignments.Ref
	|HAVING
	| SUM(RegisterDataGoodsForShipment.Demand) - MAX(ISNULL(DocumentData.Count, 0))>=0";
	
	If RequestFormationParameters.TakeIntoAccountAlreadySelected Then
		// The request is not for dynamic lists
		QueryText =
		"SELECT
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Purpose,
		|	DocumentGoods.Count
		|INTO TableOfDocumentProducts
		|FROM
		|	&DocumentGoods AS DocumentGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfDocumentProducts.Products AS Products,
		|	TableOfDocumentProducts.Characteristic AS Characteristic,
		|	TableOfDocumentProducts.Purpose AS Purpose,
		|	SUM(TableOfDocumentProducts.Count) AS Count
		|INTO GoodsOfDocumentAreGrouped
		|FROM
		|	TableOfDocumentProducts AS TableOfDocumentProducts
		|WHERE
		|	(TableOfDocumentProducts.Products, TableOfDocumentProducts.Characteristic) IN (&FilterByGoods)
		|
		|GROUP BY
		|	TableOfDocumentProducts.Products,
		|	TableOfDocumentProducts.Characteristic,
		|	TableOfDocumentProducts.Purpose
		|;" + QueryText;
	Else
		QueryText = StrReplace(QueryText, "GoodsOfDocumentAreGrouped", "(" +
			"SELECT
			|	TRUE AS Products,
			|	TRUE AS Characteristic,
			|	TRUE AS Purpose,
			|	0 AS Count" + ")");
	EndIf;
	
	If RequestFormationParameters.ForSeveralProducts Then
		// The request is not for dynamic lists
		QueryText =
		"SELECT
		|	TableOfGoods.Products,
		|	TableOfGoods.Characteristic
		|INTO ProductSelectionTable
		|FROM
		|	&TableOfGoods AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductSelectionTable.Products,
		|	ProductSelectionTable.Characteristic
		|INTO GoodsGrouped
		|FROM
		|	ProductSelectionTable AS ProductSelectionTable
		|
		|GROUP BY
		|	ProductSelectionTable.Products,
		|	ProductSelectionTable.Characteristic
		|;" + QueryText;
		QueryText = StrReplace(QueryText, "&FilterByGoods",
			"SELECT
			|	GoodsGrouped.Products,
			|	GoodsGrouped.Characteristic
			|FROM
			|	GoodsGrouped AS GoodsGrouped");
	Else
		QueryText = StrReplace(QueryText, "&FilterByGoods",
			"SELECT
			|	&Products,
			|	&Characteristic");
	EndIf;
		
	If RequestFormationParameters.SortByDateOfAppointmentOrder Then
		QueryText = QueryText + "
		|ORDER BY
		|	Assignments.OrderDocument.Date";
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the request text to check whether the series is filled in
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToCheckSeriesFilling(SeriesSpecificationParameters) Export
	
	
	If SeriesSpecificationParameters.UseBinLocationWarehousing Then
		QueryText = 
		"SELECT
		|	TableOfSeries.LineNumber AS LineNumber,
		|	TableOfSeries.Products AS Products,
		|	TableOfSeries.Characteristic AS Characteristic,
		|	TableOfSeries.Series AS Series,
		|	""Series"" AS FieldNameSeries,
		|	CASE
		|		WHEN TableOfSeries.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
		|			THEN TableOfSeries.Package
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END AS Package,
		|	CASE
		|		WHEN TableOfSeries.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
		|			THEN TableOfSeries.NumberOfPackages
		|		ELSE TableOfSeries.Count
		|	END AS NumberOfPackages
		|INTO SeriesTableForQuery
		|FROM
		|	&TableOfSeries_QueryNumber AS TableOfSeries
		|WHERE
		|	TableOfSeries.BatchesIndicationStatus > 0
		|	AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)";
	Else
		QueryText = 
		"SELECT
		|	TableOfSeries.LineNumber AS LineNumber,
		|	TableOfSeries.Products AS Products,
		|	TableOfSeries.Characteristic AS Characteristic,
		|	TableOfSeries.Series AS Series,
		|	""Series"" AS FieldNameSeries,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	TableOfSeries.Count AS NumberOfPackages
		|INTO SeriesTableForQuery
		|FROM
		|	&TableOfSeries_QueryNumber AS TableOfSeries
		|WHERE
		|	TableOfSeries.BatchesIndicationStatus > 0
		|	AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)";
	EndIf;
		
	Return QueryText;
	
EndFunction

// Splits the expense order into two, transferring lines to the receipts. If the warehouse is addressable, the reversal
// documents are generated for the transfer of goods already selected under the order.
//
// Parameters:
//	SourceObject_      - DocumentObject.GoodsIssueNote - object of the document "Expenditure order for goods".
//	StringsForReceiver  - Array - array of line numbers to be transferred to the new order.
//		Lines with packing lists will be moved recursively.
//	ReceiverLink        - DocumentRef.GoodsIssueNote, Undefined	 - receiver for portable strings.
//		If Undefined , a new order will be created. The default value is Undefined.
//	TransportationJob    - DocumentRef.TransportationJob, Undefined - if the value is not Undefined 
//		, the transport task will be filled in at the receiver.
//
// Returns:
//	DocumentRef.GoodsIssueNote, Undefined - the receiver order link or Undefined if an error occurred.
//
Function BreakOrder(SourceObject_, StringsForReceiver, ReceiverLink = Undefined, TransportationJob = Undefined) Export
	
	If Not ValueIsFilled(ReceiverLink) Then
		ReceiverObject_ = Documents.GoodsIssueNote.CreateDocument();
		FillPropertyValues(ReceiverObject_, SourceObject_,, "Date,Number");
		
		If ValueIsFilled(TransportationJob) Then
			ReceiverObject_.TransportationJob = TransportationJob;
		EndIf;
		
		ReceiverObject_.Date = CurrentSessionDate();
	Else
		ReceiverObject_ = ReceiverLink.GetObject();
		Try
			ReceiverObject_.Lock();
		Except
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
			Return Undefined;
		EndTry;
	EndIf;
	
	
	ResultOfCalculationOfPortableStrings = PortableStrings(SourceObject_, StringsForReceiver); 
	
	If ResultOfCalculationOfPortableStrings.HasError Then
		Return Undefined;
	EndIf;
	
	If WarehousesServer.UseBinLocationWarehousing(SourceObject_.Warehouse, SourceObject_.Premise, SourceObject_.DateOfShipment) Then
		AdjustingObject = Documents.InventoryAdjustmentGoodsShipmentOrder.CreateDocument();
		FillPropertyValues(AdjustingObject, SourceObject_, "Warehouse,Premise");
		AdjustingObject.Date = CurrentSessionDate();
		AdjustingObject.WarehouseDocument = SourceObject_.Ref;
	Else
		AdjustingObject = Undefined;
	EndIf;
	
	For Each ArrRow In ResultOfCalculationOfPortableStrings.LinesToWrap Do
		
		NewRow = ReceiverObject_.ShippedGoods.Add();	
		FillPropertyValues(NewRow, ArrRow); 
		
		If AdjustingObject <> Undefined
			And Not ArrRow.ThisIsAPackingList Then
			NewAdjustmentLine = AdjustingObject.Goods.Add();
			FillPropertyValues(NewAdjustmentLine, ArrRow); 
			NewAdjustmentLine.OperationKind = Enums.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote;
		EndIf;
			
		SourceObject_.ShippedGoods.Delete(ArrRow);
	EndDo;
	
	SourceObject_.TotalNumberOfPackageItems = PackingListsServer.NumberOfSeatsWH(SourceObject_.ShippedGoods);	
	ReceiverObject_.TotalNumberOfPackageItems = PackingListsServer.NumberOfSeatsWH(ReceiverObject_.ShippedGoods);	
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsByReferences.LineNumber,
	|	GoodsByReferences.ReferenceOrder,
	|	GoodsByReferences.Products,
	|	GoodsByReferences.Characteristic,
	|	GoodsByReferences.Purpose,
	|	GoodsByReferences.Series,
	|	GoodsByReferences.Count
	|INTO GoodsOnOrdersForRequest
	|FROM
	|	&GoodsByReferences AS GoodsByReferences
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	CASE
	|		WHEN ShippedGoods.BatchesIndicationStatus IN (10, 14)
	|			THEN ShippedGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	ShippedGoods.Count
	|INTO ShippedGoods
	|FROM
	|	&ShippedGoods AS ShippedGoods
	|WHERE
	|	NOT ShippedGoods.ThisIsAPackingList
	|	AND ShippedGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TransportationTask.ReferenceOrder
	|INTO OrdersTasks
	|FROM
	|	Document.TransportationJob.References AS TransportationTask
	|WHERE
	|	TransportationTask.Ref = &TransportationJob
	|	AND TransportationTask.RecipientSender = &Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsByReferences.LineNumber,
	|	GoodsByReferences.ReferenceOrder,
	|	CASE
	|		WHEN OrdersTasks.ReferenceOrder IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS OrderIsInTask,
	|	GoodsByReferences.Products,
	|	GoodsByReferences.Characteristic,
	|	GoodsByReferences.Purpose,
	|	GoodsByReferences.Series,
	|	GoodsByReferences.Count
	|INTO GoodsByReferences
	|FROM
	|	GoodsOnOrdersForRequest AS GoodsByReferences
	|		LEFT JOIN OrdersTasks AS OrdersTasks
	|		ON GoodsByReferences.ReferenceOrder = OrdersTasks.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllGoods.Products,
	|	AllGoods.Characteristic,
	|	AllGoods.Purpose,
	|	AllGoods.Series,
	|	SUM(AllGoods.QuantityByOrder_) - SUM(AllGoods.QuantityShipped_) AS DiscrepancyWithOrders
	|INTO ProductDiscrepancies
	|FROM
	|	(SELECT
	|		GoodsByReferences.Products AS Products,
	|		GoodsByReferences.Characteristic AS Characteristic,
	|		GoodsByReferences.Purpose AS Purpose,
	|		GoodsByReferences.Series AS Series,
	|		0 AS QuantityShipped_,
	|		GoodsByReferences.Count AS QuantityByOrder_
	|	FROM
	|		GoodsByReferences AS GoodsByReferences
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShippedGoods.Products,
	|		ShippedGoods.Characteristic,
	|		ShippedGoods.Purpose,
	|		ShippedGoods.Series,
	|		ShippedGoods.Count,
	|		0
	|	FROM
	|		ShippedGoods AS ShippedGoods) AS AllGoods
	|
	|GROUP BY
	|	AllGoods.Products,
	|	AllGoods.Purpose,
	|	AllGoods.Characteristic,
	|	AllGoods.Series
	|
	|HAVING
	|	SUM(AllGoods.QuantityShipped_) < SUM(AllGoods.QuantityByOrder_)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductDiscrepancies.Products AS Products,
	|	ProductDiscrepancies.Characteristic AS Characteristic,
	|	ProductDiscrepancies.Purpose AS Purpose,
	|	ProductDiscrepancies.Series AS Series,
	|	ProductDiscrepancies.DiscrepancyWithOrders,
	|	GoodsByReferences.LineNumber AS OrderLineNumber
	|FROM
	|	GoodsByReferences AS GoodsByReferences
	|		INNER JOIN ProductDiscrepancies AS ProductDiscrepancies
	|		ON GoodsByReferences.Products = ProductDiscrepancies.Products
	|			AND GoodsByReferences.Characteristic = ProductDiscrepancies.Characteristic
	|			AND GoodsByReferences.Purpose = ProductDiscrepancies.Purpose
	|			AND GoodsByReferences.Series = ProductDiscrepancies.Series
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	GoodsByReferences.OrderIsInTask DESC";
	
	Query.SetParameter("GoodsByReferences",SourceObject_.GoodsByReferences.Unload());
	Query.SetParameter("ShippedGoods",SourceObject_.ShippedGoods.Unload());
	Query.SetParameter("ShippedGoods",SourceObject_.ShippedGoods.Unload());
	Query.SetParameter("TransportationJob",ReceiverObject_.TransportationJob);
	Query.SetParameter("Recipient",ReceiverObject_.Recipient);
	
	CurProducts   = Undefined;
	CurCharacteristic = Undefined;
	CurPurpose     = Undefined;
	CurSeries          = Undefined;
	
	Selection = Query.Execute().Select();
	
	RowsForDeletion = New Array;
	
	While Selection.Next() Do
		
		If CurProducts <> Selection.Products
			Or CurCharacteristic <> Selection.Characteristic
			Or CurPurpose <> Selection.Purpose
			Or CurSeries <> Selection.Series Then
			
			QuantityToDistribution = Selection.DiscrepancyWithOrders;
			
			CurProducts   = Selection.Products;
			CurCharacteristic = Selection.Characteristic;
			CurPurpose     = Selection.Purpose;
			CurSeries          = Selection.Series;
			
		EndIf;
		
		If QuantityToDistribution = 0 Then
			Continue;
		EndIf;
		
		Orders_Row = SourceObject_.GoodsByReferences[Selection.OrderLineNumber - 1];
		NewRow        = ReceiverObject_.GoodsByReferences.Add();	
		FillPropertyValues(NewRow, Orders_Row); 
		
		If QuantityToDistribution >= Orders_Row.Count Then
			QuantityToDistribution = QuantityToDistribution - Orders_Row.Count;
			RowsForDeletion.Add(Orders_Row);
		Else
			Orders_Row.Count = Orders_Row.Count - QuantityToDistribution;
			NewRow.Count        = QuantityToDistribution;
			QuantityToDistribution      = 0;
		EndIf;
		
	EndDo;
	
	For Each ArrRow In RowsForDeletion Do
		
		SourceObject_.GoodsByReferences.Delete(ArrRow);
		
	EndDo;
	
	TransactionCommitted = True;
	BeginTransaction();
	
	Try
		SourceObject_.AdditionalProperties.Insert("DisableMonitoringWhenConducting");
		
		If SourceObject_.ShippedGoods.Count() > 0 Then
			SourceObject_.Write(DocumentWriteMode.Posting);
		Else
			SourceObject_.Write(DocumentWriteMode.UndoPosting);
		EndIf;
			
		ReceiverObject_.AdditionalProperties.Insert("DisableMonitoringWhenConducting");
		ReceiverObject_.Write(DocumentWriteMode.Posting);
		
		If AdjustingObject <> Undefined Then
			AdjustingObject.RecipientNote = ReceiverObject_.Ref;
			AdjustingObject.Write(DocumentWriteMode.Posting);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		TransactionCommitted = False;
		
		MessageText = NStr("vi = 'Không thể phân chia đơn hàng %Source%';
							|ru = 'Не удалось разбить ордер %Source%';
							|en = 'Cannot split note %Source%'; fa = 'Cannot split note %Source%';
							|it = 'Non è stato possibile frazionare l''ordine %Source%';
							|pl = 'Nie udało się podzielić zlecenie %Source%';
							|tr = 'Sipariş bölünemedi %Source%'");
		MessageText = StrReplace(MessageText, "%Source%", SourceObject_.Ref);
		CommonClientServer.MessageToUser(MessageText);
		
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode(); // To record an event in the registration Log.
		WriteLogEvent(NStr("vi = 'Không thể chuyển dữ liệu sang lệnh mới';
							|ru = 'Не удалось перенести данные в новый ордер';
							|en = 'Cannot transfer data to a new note'; fa = 'Cannot transfer data to a new note';
							|it = 'Non è stato possibile trasferire i dati nel nuovo ordine';
							|pl = 'Nie udało się przenieść dane do nowego zlecenia';
							|tr = 'Veriler yeni siparişe aktarılamadı'", DefaultLanguageCode),
			EventLogLevel.Error, , ,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If TransactionCommitted Then
		Return ReceiverObject_.Ref;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Warehouse)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - composition of properties See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ThisIsAnInvoice			= False;
	JobPrintingRules.FieldNameRoom		= "Premise";
	JobPrintingRules.NameTSGoods			= "ShippedGoods";
	JobPrintingRules.ThereArePackingLists	= True;
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

#EndIf

#EndRegion

#Region Private

#If Not MobileStandaloneServer Then

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.GoodsIssueNote"; 
	
	If RegisterName = "GoodsBatchMovement" Then
		
		QueryText = QueryTextTableGoodsBatchMovement(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "SeriesTable";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(QueryText,
																									FullDocumentName,
																									SynonymForDocumentTable);

	Return Result;

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.Text = 
		"SELECT
		|	DocumentDataHeader.DateOfShipment AS Period,
		|	DocumentDataHeader.Warehouse AS Warehouse,
		|	DocumentDataHeader.Recipient AS Recipient,
		|	DocumentDataHeader.WarehouseOperation AS WarehouseOperation,
		|	DocumentDataHeader.TransportationJob AS TransportationJob,
		|	DocumentDataHeader.Premise AS Premise,
		|	DocumentDataHeader.ShippingZone AS ShippingZone,
		|	DocumentDataHeader.Status AS Status
		|FROM
		|	DocumentDataHeader AS DocumentDataHeader";

	Result = Query.Execute();

	ParametersStructure = TMCommonUse.FirstLineOfQueryResultInStructure(Result);
	TMCommonUse.SetRequestParameters(Query, ParametersStructure);

EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	Query.TempTablesManager = New TempTablesManager();

	If DocumentRef = Undefined Then
		Return;
	EndIf;

	ListOfRequests = New Array;

	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableShippedItems(ListOfRequests);
	QueryTextDocumentDataTableItemsByOrder(ListOfRequests);

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());

	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();

EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader = 
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.DateOfShipment AS DateOfShipment,
		|	DocumentData.Warehouse AS Warehouse,
		|	DocumentData.Recipient AS Recipient,
		|	DocumentData.WarehouseOperation AS WarehouseOperation,
		|	DocumentData.Premise AS Premise,
		|	DocumentData.ControlledLotReference AS ControlledLotReference,
		|	DocumentData.Status AS Status,
		|	DocumentData.TransportationJob AS TransportationJob,
		|	DocumentData.ShippingZone AS ShippingZone
		|INTO DocumentDataHeader
		|FROM
		|	Document.GoodsIssueNote AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|
		|INDEX BY
		|	Ref";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableShippedItems(ListOfRequests)
	
	QueryTextTableGoods =
		"SELECT
		|	TableOfItemsShipped.Ref AS Ref,
		|	TableOfItemsShipped.Products AS Products,
		|	TableOfItemsShipped.Characteristic AS Characteristic,
		|	TableOfItemsShipped.Purpose AS Purpose,
		|	TableOfItemsShipped.Count AS Count,
		|	TableOfItemsShipped.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	TableOfItemsShipped.Series AS Series,
		|	TableOfItemsShipped.Action AS Action,
		|	TableOfItemsShipped.Package AS Package,
		|	Packages.PackageType AS PackagingTypeOfPackaging,
		|	TableOfItemsShipped.ThisIsAPackingList AS ThisIsAPackingList,
		|	TableOfItemsShipped.NumberOfPackages AS NumberOfPackages
		|INTO DocumentDataTableShippedItems
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS TableOfItemsShipped
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
		|		ON (Packages.Ref = TableOfItemsShipped.Package)
		|WHERE
		|	TableOfItemsShipped.Ref = &Ref
		|
		|INDEX BY
		|	Ref";

	ListOfRequests.Add(QueryTextTableGoods);

EndProcedure

Procedure QueryTextDocumentDataTableItemsByOrder(ListOfRequests)
	
	QueryTextTableGoodsByReferences =
		"SELECT
		|	TableOfItemsByOrder.Ref AS Ref,
		|	TableOfItemsByOrder.Products AS Products,
		|	TableOfItemsByOrder.Characteristic AS Characteristic,
		|	TableOfItemsByOrder.Purpose AS Purpose,
		|	TableOfItemsByOrder.Count AS Count,
		|	TableOfItemsByOrder.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	TableOfItemsByOrder.Series AS Series,
		|	TableOfItemsByOrder.ReferenceOrder AS ReferenceOrder
		|INTO DocumentDataTableItemsByOrder
		|FROM
		|	Document.GoodsIssueNote.GoodsByReferences AS TableOfItemsByOrder
		|WHERE
		|	TableOfItemsByOrder.Ref = &Ref
		|
		|INDEX BY
		|	Ref";

	ListOfRequests.Add(QueryTextTableGoodsByReferences);

EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = 
		"SELECT
		|	DocumentDataHeader.DateOfShipment AS Period,
		|	SeriesTable.Products AS Products,
		|	SeriesTable.Characteristic AS Characteristic,
		|	CASE
		|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
		|			THEN SeriesTable.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	SeriesTable.Series AS Series,
		|	SeriesTable.Count AS Count,
		|	DocumentDataHeader.Warehouse AS Sender,
		|	DocumentDataHeader.Premise AS WareroomOfSender,
		|	DocumentDataHeader.Recipient AS Recipient,
		|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfRecipient,
		|	SeriesTable.Ref AS Document,
		|	DocumentDataHeader.WarehouseOperation AS WarehouseOperation,
		|	TRUE AS ThisIsWarehouseRecord
		|FROM
		|	TTTableProducts AS SeriesTable
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON (DocumentDataHeader.Ref = SeriesTable.Ref)
		|WHERE
		|	SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	AND SeriesTable.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.DateOfShipment,
		|	SeriesTable.Products,
		|	SeriesTable.Characteristic,
		|	CASE
		|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
		|			THEN SeriesTable.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END,
		|	SeriesTable.Series,
		|	SeriesTable.Count,
		|	DocumentDataHeader.Warehouse,
		|	DocumentDataHeader.Premise,
		|	DocumentDataHeader.Warehouse,
		|	DocumentDataHeader.Premise,
		|	SeriesTable.Ref,
		|	VALUE(Enum.WarehouseTransactions.PlacementIntoBins),
		|	TRUE
		|FROM
		|	TTTableProducts AS SeriesTable
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON (DocumentDataHeader.Ref = SeriesTable.Ref)
		|WHERE
		|	SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	AND SeriesTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextDelivery(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "Delivery";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not GoodsDeliveryClientServer.UsedDelivery25()
	 Or Not DocumentObject.ShipmentUnderTransportationJob
	 Or TypeOf(DocumentObject.TransportationJob) <> Type("DocumentRef.Trip") Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentHeader.DateOfShipment AS Period,
	|	DocumentsRegistry.Organization AS Organization,
	|	VALUE(Enum.DeliveryTypes.OutgoingInfo) AS DeliveryType,
	|	DocumentHeader.DateOfShipment AS DateOfShipment,
	|	DocumentHeader.Warehouse AS Sender,
	|	DocumentHeader.Recipient AS Recipient,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	DocumentHeader.TransportationJob AS Trip,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	1 AS Arm,
	|	CASE
	|		WHEN DocumentHeader.Status = VALUE(Enum.GoodsIssueNoteStatuses.Prepared)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS KittingIsScheduled,
	|	CASE
	|		WHEN DocumentHeader.Status IN (&StatusesGoingTo)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS AssemblyInProgress,
	|	CASE
	|		WHEN DocumentHeader.Status IN (&StatusesCollected)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS Assembled,
	|	GoodsTable.Purpose AS Purpose
	|FROM
	|	DocumentDataTableItemsByOrder AS GoodsTable
	|		LEFT JOIN DocumentDataHeader AS DocumentHeader
	|		ON GoodsTable.Ref = DocumentHeader.Ref
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON GoodsTable.ReferenceOrder = DocumentsRegistry.Ref
	|			AND (NOT DocumentsRegistry.AdditionalRecord)";
	
	StatusesGoingTo = New Array; // Array of EnumRef.GoodsIssueNoteStatuses
	StatusesGoingTo.Add(Enums.GoodsIssueNoteStatuses.ForPicking);
	StatusesGoingTo.Add(Enums.GoodsIssueNoteStatuses.ForChecking);
	StatusesGoingTo.Add(Enums.GoodsIssueNoteStatuses.DuringChecking);
	StatusesGoingTo.Add(Enums.GoodsIssueNoteStatuses.Verified);
	Query.SetParameter("StatusesGoingTo", StatusesGoingTo);
	
	StatusesCollected = New Array; // Array of EnumRef.GoodsIssueNoteStatuses
	StatusesCollected.Add(Enums.GoodsIssueNoteStatuses.ToShip);
	StatusesCollected.Add(Enums.GoodsIssueNoteStatuses.Shipped_);
	Query.SetParameter("StatusesCollected", StatusesCollected);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
	
Function QueryTextTTTableProducts(Query, QueryTexts)
	
	RegisterName = "TTTableProducts";
		
	QueryText = 
	"SELECT
	|	ItemsShippedItems.Ref AS Ref,
	|	ItemsShippedItems.Products AS Products,
	|	ItemsShippedItems.Characteristic AS Characteristic,
	|	ItemsShippedItems.Purpose AS Purpose,
	|	ItemsShippedItems.Series AS Series,
	|	ItemsShippedItems.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	ItemsShippedItems.Action AS Action,
	|	ItemsShippedItems.Count AS Count
	|INTO TTTableProducts
	|FROM
	|	DocumentDataTableShippedItems AS ItemsShippedItems
	|WHERE
	|	ItemsShippedItems.Ref IN(&Ref)
	|	AND NOT ItemsShippedItems.ThisIsAPackingList
	|	AND ISNULL(ItemsShippedItems.PackagingTypeOfPackaging, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	Table.Action,
	|	SUM(ShippedGoodsQuantity.Count)
	|FROM
	|	(SELECT
	|		ShippedGoodsPackage.Ref AS Ref,
	|		ShippedGoodsPackage.Products AS Products,
	|		ShippedGoodsPackage.Characteristic AS Characteristic,
	|		ShippedGoodsPackage.Purpose AS Purpose,
	|		ShippedGoodsPackage.Series AS Series,
	|		MAX(ShippedGoodsPackage.Package) AS Package,
	|		ShippedGoodsPackage.Action AS Action,
	|		ShippedGoodsPackage.BatchesIndicationStatus AS BatchesIndicationStatus
	|	FROM
	|		DocumentDataTableShippedItems AS ShippedGoodsPackage
	|	WHERE
	|		ShippedGoodsPackage.Ref IN(&Ref)
	|		AND NOT ShippedGoodsPackage.ThisIsAPackingList
	|		AND ISNULL(ShippedGoodsPackage.PackagingTypeOfPackaging, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	
	|	GROUP BY
	|		ShippedGoodsPackage.Ref,
	|		ShippedGoodsPackage.Products,
	|		ShippedGoodsPackage.Characteristic,
	|		ShippedGoodsPackage.Purpose,
	|		ShippedGoodsPackage.Action,
	|		ShippedGoodsPackage.Series,
	|		ShippedGoodsPackage.BatchesIndicationStatus) AS Table
	|		INNER JOIN DocumentDataTableShippedItems AS ShippedGoodsQuantity
	|		ON Table.Ref = ShippedGoodsQuantity.Ref
	|			AND Table.Products = ShippedGoodsQuantity.Products
	|			AND Table.Characteristic = ShippedGoodsQuantity.Characteristic
	|			AND Table.Series = ShippedGoodsQuantity.Series
	|			AND Table.Purpose = ShippedGoodsQuantity.Purpose
	|			AND Table.Package = ShippedGoodsQuantity.Package
	|			AND Table.Action = ShippedGoodsQuantity.Action
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.Action,
	|	Table.BatchesIndicationStatus";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ShipGoodsFromWarehouse_(Query, QueryTexts, Registers, DocumentObject)

	If DocumentObject <> Undefined
		And DocumentObject.Status = Enums.GoodsIssueNoteStatuses.EmptyRef() Then
		Return;
	EndIf;

	TextOfDocumentDataRequest = 
		"SELECT
		|	DocumentGoods.Ref AS Ref,
		|	HeaderData_.DateOfShipment AS Period,
		|	DocumentGoods.ReferenceOrder AS OrderDocument,
		|	HeaderData_.TransportationJob AS TransportationJob,
		|	HeaderData_.Recipient AS Recipient,
		|	HeaderData_.Warehouse AS Warehouse,
		|	VALUE(Catalog.Warerooms.EmptyRef) AS Premise,
		|	VALUE(Catalog.StorageBins.EmptyRef) AS Cell,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.Purpose AS Purpose,
		|	HeaderData_.ControlledLotReference AS ControlledLotReference,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	DocumentGoods.Series AS Series,
		|	DocumentGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	DocumentGoods.Count AS Count,
		|	0 AS NumberOfPackages,
		|	VALUE(Enum.ActionsWithGoodsIssueNoteRows.EmptyRef) AS Action,
		|	HeaderData_.Status = VALUE(Enum.GoodsIssueNoteStatuses.Prepared) AS ForAssembly,
		|	HeaderData_.Status IN (VALUE(Enum.GoodsIssueNoteStatuses.ForPicking), VALUE(Enum.GoodsIssueNoteStatuses.ForChecking)) AS AssemblyInProgress,
		|	HeaderData_.Status IN (VALUE(Enum.GoodsIssueNoteStatuses.Verified), VALUE(Enum.GoodsIssueNoteStatuses.ToShip)) AS Assembled,
		|	HeaderData_.Status = VALUE(Enum.GoodsIssueNoteStatuses.Shipped_) AS ToShip
		|FROM
		|	DocumentDataTableItemsByOrder AS DocumentGoods
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = DocumentGoods.Ref)
		|WHERE
		|	DocumentGoods.Ref IN(&Ref)
		|	AND HeaderData_.Status <> VALUE(Enum.GoodsIssueNoteStatuses.EmptyRef)
		|	AND DocumentGoods.Count <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentGoods.Ref,
		|	HeaderData_.DateOfShipment,
		|	UNDEFINED,
		|	VALUE(Document.TransportationJob.EmptyRef),
		|	UNDEFINED,
		|	HeaderData_.Warehouse,
		|	HeaderData_.Premise,
		|	HeaderData_.ShippingZone,
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Purpose,
		|	HeaderData_.ControlledLotReference AS ControlledLotReference,
		|	DocumentGoods.Package,
		|	DocumentGoods.Series,
		|	DocumentGoods.BatchesIndicationStatus,
		|	DocumentGoods.Count,
		|	DocumentGoods.NumberOfPackages,
		|	DocumentGoods.Action,
		|	HeaderData_.Status = VALUE(Enum.GoodsIssueNoteStatuses.Prepared),
		|	HeaderData_.Status IN (VALUE(Enum.GoodsIssueNoteStatuses.ForPicking), VALUE(Enum.GoodsIssueNoteStatuses.ForChecking)),
		|	HeaderData_.Status IN (VALUE(Enum.GoodsIssueNoteStatuses.Verified), VALUE(Enum.GoodsIssueNoteStatuses.ToShip)),
		|	HeaderData_.Status = VALUE(Enum.GoodsIssueNoteStatuses.Shipped_)
		|FROM
		|	DocumentDataTableShippedItems AS DocumentGoods
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = DocumentGoods.Ref)
		|WHERE
		|	DocumentGoods.Ref IN(&Ref)
		|	AND NOT DocumentGoods.ThisIsAPackingList
		|	AND DocumentGoods.Count <> 0
		|	AND HeaderData_.Status <> VALUE(Enum.GoodsIssueNoteStatuses.EmptyRef)";

	WarehousesServer.ShipGoodsFromWarehouse_(Query, QueryTexts, Registers, TextOfDocumentDataRequest);

EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If AccessRight("Update", Metadata.Documents.GoodsIssueNote) Then
		// Expenditure order for goods
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "GoodsIssueNote";
		PrintCommand.Presentation = NStr("vi = 'Phiếu xuất kho';
										|ru = 'Расходный ордер на товары';
										|en = 'Goods issue'; fa = 'حواله انبار';
										|it = 'Mandato di pagamento per le merci';
										|pl = 'Asygnata rozchodowa na wiersze pozycji';
										|tr = 'ambar çıkış fişi'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	

	// Task for the selection of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask");
	PrintCommand.AdditionalParameters.Insert("PrintingFromDocumentData");
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsIssueNote") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsIssueNote",
			NStr("vi = 'Phiếu xuất kho';
				|ru = 'Расходный ордер на товары';
				|en = 'Goods issue'; fa = 'حواله انبار';
				|it = 'Mandato di pagamento per le merci';
				|pl = 'Asygnata rozchodowa na wiersze pozycji';
				|tr = 'ambar çıkış fişi'"),
			PrintingSpendingOrderForGoods(ObjectsArray, PrintObjects));
	EndIf;
EndProcedure

// Returns the document data structure used for printing the printed form of the product selection (placement) Task.
//
// Parameters:
//	PrintParameters	- Structure - additional print options.
//	ObjectsArray	- Array of DocumentRef - links to objects that need to be printed.
//	
// Returns:
//	Structure - a structure with the following keys:
//		*ErrorResults			- Undefined		- errors in document data that make it impossible
//															to print the document.
//		*ResultOnOrders	- QueryResult	- information about orders for document shipment.
//		*HeaderResults			- QueryResult	- the data of the header of the document used for the print Job
//															in the selection of goods.
//		*ResultForTabularPart	- QueryResult	- data of the product part of the document used for printing
//															Job in the selection of goods.
//		*ResultForPackages		- Undefined		- data about product packages in the tabular part of the document
//															used for printing the product selection Task.
//		*ResultBySeries			- QueryResult	- data about product series in the table part of the document
//															that is used for printing the product selection Task.
//		*ResultByBrand			- QueryResult	- data on the marking of goods in the tabular part of the document
//															used to print the Assignment for the placement of goods.
//
Function GetDataForPrintedFormForProductPlacement(PrintParameters, ObjectsArray) Export
	
	MarkedProductsAreUsed = GoodsIssueNoteLocalization.MarkedProductsAreUsed();
	
	QueryText =
	"SELECT
	|	DocumentData.Ref						AS Ref,
	|	DocumentData.Warehouse						AS Warehouse,
	|	DocumentData.Premise					AS Premise,
	|	MIN(DocumentGoods.LineNumber)		AS LineNumber,
	|	DocumentGoods.Products				AS Products,
	|	DocumentGoods.Characteristic				AS Characteristic,
	|	DocumentGoods.Series						AS Series,
	|	DocumentGoods.Package					AS Package,
	|	FALSE AS MarkedProducts,
	|	SUM(DocumentGoods.Count)			AS Count,
	|	SUM(DocumentGoods.NumberOfPackages)	AS NumberOfPackages
	|INTO TaskItems_
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS DocumentGoods
	|		LEFT JOIN Document.GoodsIssueNote AS DocumentData
	|		ON DocumentGoods.Ref = DocumentData.Ref
	|, ConnectionTable
	|WHERE
	|	DocumentGoods.Ref IN(&ObjectsArray)
	|	AND NOT DocumentGoods.ThisIsAPackingList
	|	AND DocumentGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Warehouse,
	|	DocumentData.Premise,
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Series,
	|	&DetailsOfItemGrouping,
	|	DocumentGoods.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref					AS Ref,
	|	GoodsTable.Warehouse						AS Warehouse,
	|	GoodsTable.Premise					AS Premise,
	|	MIN(GoodsTable.LineNumber)		AS LineNumber,
	|	GoodsTable.Products				AS Products,
	|	GoodsTable.Characteristic			AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsTable.Series
	|	END AS Series,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|				OR GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.Package
	|	END AS Package,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(CASE
	|			WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|				THEN GoodsTable.Count
	|			ELSE GoodsTable.NumberOfPackages
	|		END) AS NumberOfPackages,
	|	GoodsTable.MarkedProducts AS MarkedProducts
	|INTO TableOfGoodsSummarized
	|FROM
	|	TaskItems_ AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Premise,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsTable.Series
	|	END,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|				OR GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.Package
	|	END,
	|	GoodsTable.MarkedProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentDescription.Ref AS Ref,
	|	PRESENTATION(DocumentDescription.ReferenceOrder) AS BasisPresentation,
	|	DocumentDescription.ReferenceOrder.Number AS BaseDocumentNumber,
	|	DocumentDescription.ReferenceOrder.Date AS ReferenceDocumentDateForPrintForms,
	|	MIN(DocumentDescription.LineNumber) AS LineNumber
	|FROM
	|	Document.GoodsIssueNote.GoodsByReferences AS DocumentDescription
	|WHERE
	|	DocumentDescription.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	DocumentDescription.Ref,
	|	DocumentDescription.ReferenceOrder.Number,
	|	DocumentDescription.ReferenceOrder.Date,
	|	PRESENTATION(DocumentDescription.ReferenceOrder)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaskData_.Ref AS Ref,
	|	PRESENTATION(TaskData_.Ref) AS RefPresentation,
	|	TaskData_.Number AS Number,
	|	TaskData_.DateOfShipment AS Date,
	|	TaskData_.Warehouse AS Warehouse,
	|	PRESENTATION(TaskData_.Warehouse) AS WarehousePresentation,
	|	PRESENTATION(TaskData_.Premise) AS PremisePresentation,
	|	FALSE AS ThisIsAnInvoice,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND TaskData_.DateOfShipment >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN TaskData_.Premise.UseBinLocationWarehousing
	|							AND TaskData_.DateOfShipment >= TaskData_.Premise.StartDateOfUsingWarehouseBinSystem
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN TaskData_.Warehouse.UseBinLocationWarehousing
	|						AND TaskData_.DateOfShipment >= TaskData_.Warehouse.StartDateOfUsingWarehouseBinSystem
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS BinLocationWarehousingIsUsed,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND TaskData_.DateOfShipment >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN TaskData_.Premise.UseBinLocationWarehousingForInformation
	|							AND (NOT TaskData_.Premise.UseBinLocationWarehousing
	|								OR TaskData_.DateOfShipment < TaskData_.Premise.StartDateOfUsingWarehouseBinSystem)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN TaskData_.Warehouse.UseBinLocationWarehousingForInformation
	|						AND (NOT TaskData_.Warehouse.UseBinLocationWarehousing
	|							OR TaskData_.DateOfShipment < TaskData_.Warehouse.StartDateOfUsingWarehouseBinSystem)
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS ReferenceStorageIsUsed,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND TaskData_.DateOfShipment >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN TaskData_.Premise.WarehouseZoneUsage
	|		ELSE TaskData_.Warehouse.WarehouseZoneUsage
	|	END AS WarehouseZoneUsage,
	|	FALSE AS AdvancedWarehousingIsUsed,
	|	PRESENTATION(TaskData_.TransportationJob.Ref) AS TransportationJobPresentation,
	|	TaskData_.TransportationJob.Number AS TransportationTaskNumber,
	|	TaskData_.TransportationJob.Date AS TransportationTaskDate,
	|	TaskData_.DeliveryProcedure AS DeliveryProcedure,
	|	TaskData_.ShipmentUnderTransportationJob AS ShipmentUnderTransportationJob
	|FROM
	|	Document.GoodsIssueNote AS TaskData_
	|WHERE
	|	TaskData_.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref								AS Ref,
	|	TableOfGoods.Warehouse								AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	PRESENTATION(MainStorageBins.Cell.WarehouseZone)	AS PresentationOfWorkArea,
	|	ISNULL(MainStorageBins.Cell.TabIndex, 0)	AS TabIndex,
	|	ISNULL(MainStorageBins.Cell, &DefaultCell)	AS MainStorageBin,
	|	ISNULL(MainStorageBins.Cell.Code, """")			AS MainStorageBinPresentation,
	|	ISNULL(OtherCells.Cell.TabIndex, 0)	AS TraversalOrderAdditionalCell,
	|	ISNULL(OtherCells.Cell.Code, """")			AS CellPresentation,
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.Products.Code						AS Code,
	|	TableOfGoods.Products.SKU					AS SKU,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Products.DescriptionFull		AS ProductPresentation,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	TableOfGoods.Characteristic.DescriptionFull	AS CharacteristicPresentation,
	|	Goods.ProductKind.BatchUsageSettings	AS BatchUsageSettings,
	|	TableOfGoods.Series								AS Series,
	|	TableOfGoods.Series.Description					AS BatchPresentation,
	|	TableOfGoods.Package								AS Package,
	|	PRESENTATION(TableOfGoods.Package)				AS PresentationOfPackingUnit,
	|	PRESENTATION(Goods.UnitOfMeasure)				AS PresentationOfBasicUnitOfMeasure,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.NumberOfPackages					AS NumberOfPackages,
	|	TableOfGoods.MarkedProducts					AS MarkedProducts
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON TableOfGoods.Products = Goods.Ref
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND (MainStorageBins.MainStorageBin)
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|			AND (CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND TableOfGoods.Ref.DateOfShipment >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = MainStorageBins.Premise
	|				ELSE MainStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END)
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS OtherCells
	|		ON TableOfGoods.Products = OtherCells.Products
	|			AND (NOT OtherCells.MainStorageBin)
	|			AND TableOfGoods.Warehouse = OtherCells.Warehouse
	|			AND (CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND TableOfGoods.Ref.DateOfShipment >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = OtherCells.Premise
	|				ELSE OtherCells.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END)
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	Series
	|TOTALS BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref				AS Ref,
	|	TableOfGoods.Warehouse				AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Series.Description	AS BatchPresentation,
	|	TableOfGoods.MarkedProducts AS MarkedProducts
	|FROM
	|	TaskItems_ AS TableOfGoods
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND (MainStorageBins.MainStorageBin)
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|			AND (CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND TableOfGoods.Ref.DateOfShipment >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = MainStorageBins.Premise
	|				ELSE MainStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END)
	|WHERE
	|	TableOfGoods.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|	AND TableOfGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaskItems_.Ref,
	|	MAX(TaskItems_.MarkedProducts) AS ThereAreLabeledProducts
	|FROM
	|	TaskItems_ AS TaskItems_
	|GROUP BY
	|	TaskItems_.Ref";
	
	QueryText = StrReplace(QueryText,
								"&BatchUsageSettings",
								"VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)");
	QueryText = StrReplace(QueryText,
								"&DefaultWorkArea",
								"VALUE(Catalog.WarehouseZones.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&DefaultCell",
								"VALUE(Catalog.StorageBins.EmptyRef)");
	
	QueriesTexts = ProductsLocalization.QueryTextsForItemDetails();
	ProductsLocalization.FillInQueryTextDetailsOfItem("DocumentGoods.Products", QueriesTexts);
	If MarkedProductsAreUsed Then
		QueryText = StrReplace(QueryText, "FALSE AS MarkedProducts", QueriesTexts.DetailsOfItemSelection);
	EndIf; 
	QueryText = StrReplace(QueryText, "&DetailsOfItemGrouping", QueriesTexts.DetailsOfItemGrouping);
	QueryText = StrReplace(QueryText, ", ConnectionTable", QueriesTexts.DetailsOfConnectionNomenclature);
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	MaxIndex = Result.UBound();
	
	TaskData_ = New Structure;
	TaskData_.Insert("ErrorResults",		Undefined);
	TaskData_.Insert("ResultOnOrders",	Result[MaxIndex - 4]);
	TaskData_.Insert("HeaderResults",			Result[MaxIndex - 3]);
	TaskData_.Insert("ResultForTabularPart",	Result[MaxIndex - 2]);
	TaskData_.Insert("ResultForPackages",		Undefined);
	TaskData_.Insert("ResultBySeries",			Result[MaxIndex - 1]);
	TaskData_.Insert("ResultByBrand",			Result[MaxIndex]);
	
	Return TaskData_;
	
EndFunction

Function PrintingSpendingOrderForGoods(ObjectsArray, PrintObjects)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsIssueNote_GoodsIssueNote";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	DocumentAttributes = New Structure("Number, Date, Prefix,Presentation");
	DocumentSynonym = NStr("vi = 'Phiếu xuất kho';
							|ru = 'Расходный ордер на товары';
							|en = 'Goods issue'; fa = 'حواله انبار';
							|it = 'Mandato di pagamento per le merci';
							|pl = 'Asygnata rozchodowa na wiersze pozycji';
							|tr = 'ambar çıkış fişi'", Common.DefaultLanguageCode());
	
	UseItemPackages = GetFunctionalOption("UseItemPackages");
	
	MarkedProductsAreUsed = GoodsIssueNoteLocalization.MarkedProductsAreUsed();
	
	RequestByHeader = New Query;
	RequestByHeader.Text = 
	"SELECT
	|	GoodsIssueNote.Ref,
	|	PRESENTATION(GoodsIssueNote.Warehouse) AS WarehousePresentation_,
	|	PRESENTATION(GoodsIssueNote.Premise) AS PresentationOfPremises,
	|	PRESENTATION(GoodsIssueNote.ShippingZone) AS ShipmentAreaPresentation,
	|	PRESENTATION(GoodsIssueNote.Recipient) AS RecipientPresentation1,
	|	GoodsIssueNote.Date AS Date,
	|	GoodsIssueNote.DateOfShipment AS DateOfShipment,
	|	GoodsIssueNote.Number AS Number,
	|	GoodsIssueNote.EmployeeResponsible.Individual AS EmployeeResponsible,
	|	GoodsIssueNote.Warehouse AS Warehouse,
	|	GoodsIssueNote.Premise AS Premise,
	|	GoodsIssueNote.Warehouse.UseItemsBatch AS UseItemsBatch,
	|	GoodsIssueNote.ShipmentUnderTransportationJob AS ShipmentUnderTransportationJob,
	|	GoodsIssueNote.DeliveryProcedure AS DeliveryProcedure,
	|	GoodsIssueNote.TransportationJob.Date AS TransportationTaskDate,
	|	GoodsIssueNote.TransportationJob.Number AS TransportationTaskNumber,
	|	PRESENTATION(GoodsIssueNote.TransportationJob) AS TransportationJobPresentation
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNote
	|WHERE
	|	GoodsIssueNote.Ref IN(&ObjectsArray)
	|
	|TOTALS BY
	|	UseItemsBatch
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsIssueNoteGoodsByReferences.Ref AS Ref,
	|	PRESENTATION(GoodsIssueNoteGoodsByReferences.ReferenceOrder.Organization.Prefix) AS OrderPrefix_,
	|	PRESENTATION(GoodsIssueNoteGoodsByReferences.ReferenceOrder) AS ReferenceOrderPresentation,
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder.Number AS OrderNumber__,
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder.Date AS Order_Date,
	|	PRESENTATION(GoodsIssueNoteGoodsByReferences.ReferenceOrder.Organization) AS RepresentationOfTheOrganization,
	|	MIN(GoodsIssueNoteGoodsByReferences.LineNumber) AS LineNumber
	|FROM
	|	Document.GoodsIssueNote.GoodsByReferences AS GoodsIssueNoteGoodsByReferences
	|WHERE
	|	GoodsIssueNoteGoodsByReferences.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	GoodsIssueNoteGoodsByReferences.Ref,
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder.Number,
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder.Date,
	|	PRESENTATION(GoodsIssueNoteGoodsByReferences.ReferenceOrder.Organization.Prefix),
	|	PRESENTATION(GoodsIssueNoteGoodsByReferences.ReferenceOrder),
	|	PRESENTATION(GoodsIssueNoteGoodsByReferences.ReferenceOrder.Organization)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber";
		
	RequestByHeader.SetParameter("ObjectsArray", ObjectsArray);
	SetPrivilegedMode(True);
	ResultsArray     = RequestByHeader.ExecuteBatch();
	SetPrivilegedMode(False);
	ObjectsTree        = ResultsArray[0].Unload(QueryResultIteration.ByGroups);
	SelectionOfOrders   = ResultsArray[1].Select();
	
	For Each UsingSeries In ObjectsTree.Rows Do
		
		RequestForProducts = New Query;
		ArrayOfObjectsUsingSeries = UsingSeries.Rows.UnloadColumn("Ref");
		RequestForProducts.SetParameter("ObjectsArray", ArrayOfObjectsUsingSeries);
		
		If UsingSeries.UseItemsBatch Then
			
			QueryTextByGoods = 
			"SELECT
			|	SpendingOrderForGoodsShippedGoods.Ref AS Ref,
			|	SpendingOrderForGoodsShippedGoods.LineNumber AS LineNumber,
			|	SpendingOrderForGoodsShippedGoods.Products.Code AS Code,
			|	SpendingOrderForGoodsShippedGoods.Products AS Products,
			|	SpendingOrderForGoodsShippedGoods.Characteristic AS Characteristic,
			|	SpendingOrderForGoodsShippedGoods.Series AS Series,
			|	SpendingOrderForGoodsShippedGoods.PackingListParent,
			|	SpendingOrderForGoodsShippedGoods.PackingListParent.Code AS PackingListParentCode,
			|	SpendingOrderForGoodsShippedGoods.NumberOfPackages,
			|	SpendingOrderForGoodsShippedGoods.Count,
			|	CASE
			|		WHEN SpendingOrderForGoodsShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS DoNotShip,
			|	FALSE AS MarkedProducts,
			|	SpendingOrderForGoodsShippedGoods.Package
			|INTO TableOfGoods
			|FROM
			|	Document.GoodsIssueNote.ShippedGoods AS SpendingOrderForGoodsShippedGoods
			|, ConnectionTable
			|
			|WHERE
			|	SpendingOrderForGoodsShippedGoods.Ref IN(&ObjectsArray)
			|	AND NOT SpendingOrderForGoodsShippedGoods.ThisIsAPackingList
			|
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Ref,
			|	MAX(TableOfGoods.LineNumber) AS LineNumber,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN NULL
			|		ELSE TableOfGoods.Series
			|	END AS Series,
			|	TableOfGoods.PackingListParent,
			|	TableOfGoods.PackingListParentCode,
			|	SUM(TableOfGoods.NumberOfPackages) AS NumberOfPackages,
			|	SUM(TableOfGoods.Count) AS Count,
			|	TableOfGoods.DoNotShip,
			|	TableOfGoods.Package,
			|	TableOfGoods.MarkedProducts			
			|INTO SummaryTableOfProducts
			|FROM
			|	TableOfGoods AS TableOfGoods
			|
			|GROUP BY
			|	TableOfGoods.Ref,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.DoNotShip,
			|	TableOfGoods.Package,
			|	TableOfGoods.MarkedProducts,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN NULL
			|		ELSE TableOfGoods.Series
			|	END,
			|	TableOfGoods.PackingListParent,
			|	TableOfGoods.PackingListParentCode
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Ref AS Ref,
			|	TableOfGoods.Products.NameOfCodeColumn AS SKU,
			|	TableOfGoods.LineNumber AS LineNumber,
			|	TableOfGoods.Products.Code AS Code,
			|	TableOfGoods.Products.DescriptionFull AS ProductPresentation,
			|	TableOfGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
			|	TableOfGoods.Series.Description AS BatchPresentation,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.PackingListParent,
			|	TableOfGoods.PackingListParentCode,
			|	TableOfGoods.NumberOfPackages,
			|	TableOfGoods.Count,
			|	TableOfGoods.DoNotShip AS DoNotShip,
			|	PRESENTATION(TableOfGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
			|	CASE
			|		WHEN TableOfGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			THEN PRESENTATION(TableOfGoods.Package)
			|		ELSE PRESENTATION(TableOfGoods.Products.UnitOfMeasure)
			|	END AS PresentationOfPackingUnit,
			|	TableOfGoods.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings,
			|	TableOfGoods.MarkedProducts
			|FROM
			|	SummaryTableOfProducts AS TableOfGoods
			|
			|ORDER BY
			|	Ref,
			|	LineNumber
			|TOTALS BY
			|	Ref,
			|	DoNotShip,
			|	PackingListParent,
			|	Products,
			|	Characteristic
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	TableOfGoods.Ref AS Ref,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Series.Description AS BatchPresentation,
			|	TableOfGoods.PackingListParent,
			|	TableOfGoods.DoNotShip AS DoNotShip,
			|	TableOfGoods.MarkedProducts AS MarkedProducts
			|FROM
			|	TableOfGoods AS TableOfGoods
			|WHERE
			|	TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|	AND NOT TableOfGoods.Series IS NULL 
			|
			|ORDER BY
			|	TableOfGoods.Ref,
			|	TableOfGoods.DoNotShip,
			|	TableOfGoods.PackingListParent,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.MarkedProducts,
			|	BatchPresentation
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Ref,
			|	MAX(TableOfGoods.MarkedProducts) AS ThereAreLabeledProducts
			|FROM
			|	TableOfGoods AS TableOfGoods
			|GROUP BY
			|	TableOfGoods.Ref";

			If OutputCodes Then
				QueryTextByGoods = StrReplace(QueryTextByGoods, "NameOfCodeColumn", NameOfCodeColumn);
			Else	
				QueryTextByGoods = StrReplace(QueryTextByGoods, "TableOfGoods.Products.NameOfCodeColumn AS SKU,", "");
			EndIf;
			
			QueriesTexts = ProductsLocalization.QueryTextsForItemDetails();
			ProductsLocalization.FillInQueryTextDetailsOfItem("SpendingOrderForGoodsShippedGoods.Products", QueriesTexts);
			If MarkedProductsAreUsed Then
				QueryTextByGoods = StrReplace(QueryTextByGoods, "FALSE AS MarkedProducts", QueriesTexts.DetailsOfItemSelection);
			EndIf;
			QueryTextByGoods = StrReplace(QueryTextByGoods, ", ConnectionTable", QueriesTexts.DetailsOfConnectionNomenclature);
			
			RequestForProducts.Text = QueryTextByGoods;
			
			ResultsArray  = RequestForProducts.ExecuteBatch();
			
			QueryResult   = ResultsArray[2]; // QueryResult
			TSSamplingByLinks = QueryResult.Select(QueryResultIteration.ByGroups);
			
			QueryResult   = ResultsArray[3]; // QueryResult
			SelectionBySeries    = QueryResult.Select();
			
			QueryResult   = ResultsArray[4]; // QueryResult
			SelectionByBrand    = QueryResult.Select();
			
		Else
			
			QueryTextByGoods = 
			"SELECT
			|	SpendingOrderForGoodsShippedGoods.Ref AS Ref,
			|	SpendingOrderForGoodsShippedGoods.LineNumber AS LineNumber,
			|	SpendingOrderForGoodsShippedGoods.Products AS Products,
			|	SpendingOrderForGoodsShippedGoods.Products.Code AS Code,
			|	SpendingOrderForGoodsShippedGoods.Products.NameOfCodeColumn AS SKU,
			|	SpendingOrderForGoodsShippedGoods.Products.DescriptionFull AS ProductPresentation,
			|	SpendingOrderForGoodsShippedGoods.Characteristic AS Characteristic,
			|	SpendingOrderForGoodsShippedGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
			|	SpendingOrderForGoodsShippedGoods.Series AS Series,
			|	SpendingOrderForGoodsShippedGoods.Series.Description AS BatchPresentation,
			|	SpendingOrderForGoodsShippedGoods.NumberOfPackages,
			|	SpendingOrderForGoodsShippedGoods.Count,
			|	CASE
			|		WHEN SpendingOrderForGoodsShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS DoNotShip,
			|	PRESENTATION(SpendingOrderForGoodsShippedGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
			|	CASE
			|		WHEN SpendingOrderForGoodsShippedGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			THEN PRESENTATION(SpendingOrderForGoodsShippedGoods.Package)
			|		ELSE PRESENTATION(SpendingOrderForGoodsShippedGoods.Products.UnitOfMeasure)
			|	END AS PresentationOfPackingUnit,
			|	SpendingOrderForGoodsShippedGoods.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings,
			|	SpendingOrderForGoodsShippedGoods.PackingListParent AS PackingListParent,
			|	FALSE AS MarkedProducts,
			|	SpendingOrderForGoodsShippedGoods.PackingListParent.Code AS PackingListParentCode
			|INTO TableOfGoods
			|FROM
			|	Document.GoodsIssueNote.ShippedGoods AS SpendingOrderForGoodsShippedGoods
			|, ConnectionTable
			|
			|WHERE
			|	SpendingOrderForGoodsShippedGoods.Ref IN(&ObjectsArray)
			|	AND NOT SpendingOrderForGoodsShippedGoods.ThisIsAPackingList
			|
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	SpendingOrderForGoodsShippedGoods.Ref AS Ref,
			|	SpendingOrderForGoodsShippedGoods.Products AS Products,
			|	SpendingOrderForGoodsShippedGoods.Characteristic AS Characteristic,
			|	SpendingOrderForGoodsShippedGoods.Products.Code AS Code,
			|	SpendingOrderForGoodsShippedGoods.Products.NameOfCodeColumn AS SKU,
			|	SpendingOrderForGoodsShippedGoods.Products.DescriptionFull AS ProductPresentation,
			|	SpendingOrderForGoodsShippedGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
			|	SpendingOrderForGoodsShippedGoods.Series AS Series,
			|	SpendingOrderForGoodsShippedGoods.BatchPresentation AS BatchPresentation,
			|	SpendingOrderForGoodsShippedGoods.NumberOfPackages,
			|	SpendingOrderForGoodsShippedGoods.Count,
			|	SpendingOrderForGoodsShippedGoods.DoNotShip,
			|	SpendingOrderForGoodsShippedGoods.PresentationOfBasicUnitOfMeasure,
			|	SpendingOrderForGoodsShippedGoods.PresentationOfPackingUnit,
			|	SpendingOrderForGoodsShippedGoods.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings,
			|	SpendingOrderForGoodsShippedGoods.PackingListParent AS PackingListParent,
			|	SpendingOrderForGoodsShippedGoods.PackingListParent.Code AS PackingListParentCode,
			|	SpendingOrderForGoodsShippedGoods.MarkedProducts
			|FROM
			|	TableOfGoods AS SpendingOrderForGoodsShippedGoods
			|
			|ORDER BY
			|	Ref,
			|	LineNumber
			|TOTALS BY
			|	Ref,
			|	DoNotShip,
			|	PackingListParent,
			|	Products,
			|	Characteristic
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Ref,
			|	MAX(TableOfGoods.MarkedProducts) AS ThereAreLabeledProducts
			|FROM
			|	TableOfGoods AS TableOfGoods
			|GROUP BY
			|	TableOfGoods.Ref";
			
			If OutputCodes Then
				QueryTextByGoods = StrReplace(QueryTextByGoods, "NameOfCodeColumn", NameOfCodeColumn);
			Else	
				QueryTextByGoods = StrReplace(QueryTextByGoods, "SpendingOrderForGoodsShippedGoods.Products.NameOfCodeColumn AS SKU,", "");
			EndIf;
			
			QueriesTexts = ProductsLocalization.QueryTextsForItemDetails();
			ProductsLocalization.FillInQueryTextDetailsOfItem("SpendingOrderForGoodsShippedGoods.Products", QueriesTexts);
			If MarkedProductsAreUsed Then
				QueryTextByGoods = StrReplace(QueryTextByGoods, "FALSE AS MarkedProducts", QueriesTexts.DetailsOfItemSelection);
			EndIf;
			QueryTextByGoods = StrReplace(QueryTextByGoods, ", ConnectionTable", QueriesTexts.DetailsOfConnectionNomenclature);
			
			RequestForProducts.Text = QueryTextByGoods;
			
			ResultsArray  = RequestForProducts.ExecuteBatch();
			
			QueryResult   = ResultsArray[1]; // QueryResult
			TSSamplingByLinks = QueryResult.Select(QueryResultIteration.ByGroups);
			
			QueryResult   = ResultsArray[2]; // QueryResult
			SelectionByBrand    = QueryResult.Select();
		
		EndIf;
		
		Query = New Query;
		Query.Text = "
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN SpendingOrderForGoodsShippedGoods.PackingListParent = VALUE(Document.PackingList.EmptyRef)
		|			THEN SpendingOrderForGoodsShippedGoods.Ref
		|		ELSE SpendingOrderForGoodsShippedGoods.PackingListParent
		|	END AS PackingListParent,
		|	SpendingOrderForGoodsShippedGoods.PackingList AS PackingList,
		|	SpendingOrderForGoodsShippedGoods.Ref AS Ref,
		|	SpendingOrderForGoodsShippedGoods.PackingList.Date AS Date,
		|	SpendingOrderForGoodsShippedGoods.PackingList.Code AS Code,
		|	CASE
		|		WHEN SpendingOrderForGoodsShippedGoods.PackingListParent = VALUE(Document.PackingList.EmptyRef)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereIsNesting
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS SpendingOrderForGoodsShippedGoods
		|WHERE
		|	SpendingOrderForGoodsShippedGoods.Ref IN(&ObjectsArray)
		|	AND SpendingOrderForGoodsShippedGoods.ThisIsAPackingList";
		
		Query.SetParameter("ObjectsArray", ArrayOfObjectsUsingSeries);
		PackingListsForDocuments = Query.Execute().Unload();
		
		FirstDocument = True;
	
		For Each SelectionByDocuments In UsingSeries.Rows Do
			
			If Not TSSamplingByLinks.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
				Continue;
			EndIf;
			
			If SelectionByBrand.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
				DisplayStamps = SelectionByBrand.ThereAreLabeledProducts;
			Else	
				DisplayStamps = False;
			EndIf;
			
			PackingSheetsOfDocument = PackingListsForDocuments.Copy(New Structure("Ref",SelectionByDocuments.Ref));
		
			BinLocationWarehousingIsUsed = WarehousesServer.UseBinLocationWarehousing(SelectionByDocuments.Warehouse, SelectionByDocuments.Premise, SelectionByDocuments.DateOfShipment);
			DisplayPackingLists = GetFunctionalOption("UsePackingLists")
				And PackingSheetsOfDocument.Count() > 0;
			
			DisplayingPackages = UseItemPackages Or BinLocationWarehousingIsUsed;
			
			// We get the layout in a loop, because the width of the columns depends on the warehouse and the room in the document.
			Template = PrintManagement.PrintFormTemplate("Document.GoodsIssueNote.PF_MXL_GoodsIssueNote");
			
			HeaderArea_ 		  = Template.GetArea("Title");
			TransportTaskArea = Template.GetArea("TransportationJob");
			SectionHeader 			  = Template.GetArea("Header");
			ScopeOfApplication_5	 	  = Template.GetArea("Customer");
			
			AreaHeaderTablesPackingLists  = Template.GetArea("HeaderTablesPackingLists");  
			AreaRowTablePackingLists = Template.GetArea("RowTablePackingLists");
			AreaBasementTablePackingLists = Template.GetArea("BasementTablesPackingLists");
			
			Area_TableHeader   = Undefined;
			AreaTableRow  = Undefined;
			TableBasementArea  = Undefined;
			
			If Not DisplayPackingLists And Not OutputCodes And Not DisplayingPackages Then
				Area_TableHeader  = Template.GetArea("TableHeader");
				AreaTableRow = Template.GetArea("TableRow");
				TableBasementArea = Template.GetArea("TableFooter");
			ElsIf DisplayPackingLists And Not OutputCodes And Not DisplayingPackages Then 
				Area_TableHeader  = Template.GetArea("HeaderTablePackingList");
				AreaTableRow = Template.GetArea("RowTablePackingList");
				TableBasementArea = Template.GetArea("BasementTablePackingList");
			ElsIf Not DisplayPackingLists And OutputCodes And Not DisplayingPackages Then
				Area_TableHeader  = Template.GetArea("TableHeaderCodeColumn");
				AreaTableRow = Template.GetArea("TableRowColumnOfCodes");
				TableBasementArea = Template.GetArea("BasementTableColumnCodes");
			ElsIf Not DisplayPackingLists And Not OutputCodes And DisplayingPackages Then
				Area_TableHeader  = Template.GetArea("PackingTableCap");
				AreaTableRow = Template.GetArea("PackingTableRow");
				TableBasementArea = Template.GetArea("BasementPackingTable");
			ElsIf DisplayPackingLists And OutputCodes And Not DisplayingPackages Then
				Area_TableHeader  = Template.GetArea("TableHeaderPackingListCodeColumn");
				AreaTableRow = Template.GetArea("TableRowPackingListCodeColumn");
				TableBasementArea = Template.GetArea("BasementTablePackingListColumnCodes");
			ElsIf Not DisplayPackingLists And OutputCodes And DisplayingPackages Then
				Area_TableHeader  = Template.GetArea("TableHeaderColumnOfPackingCodes");
				AreaTableRow = Template.GetArea("TableRowColumnOfPackingCodes");
				TableBasementArea = Template.GetArea("BasementTableColumnOfPackingCodes");
			ElsIf DisplayPackingLists And Not OutputCodes And DisplayingPackages Then
				Area_TableHeader  = Template.GetArea("CapTablePackingListPackaging");
				AreaTableRow = Template.GetArea("RowTablePackingListPackaging");
				TableBasementArea = Template.GetArea("BasementTablePackingListPackaging");
			ElsIf DisplayPackingLists And OutputCodes And DisplayingPackages Then
				Area_TableHeader  = Template.GetArea("HeaderOfAllTable");
				AreaTableRow = Template.GetArea("TableRowAll");
				TableBasementArea = Template.GetArea("BasementTablesAreAll");
			EndIf;
						
			If OutputCodes Then 
				Area_TableHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
			EndIf;
			
			SignatureArea = Template.GetArea("Signatures");
			
			AreaHeaderDoNotShip = Template.GetArea("DonTShipHeader");
			
			If Not FirstDocument Then
				SpreadsheetDocument.PutHorizontalPageBreak();
			EndIf;
			
			FirstDocument = False;
			RowNumberStart = SpreadsheetDocument.TableHeight + 1;
			
			// Output the header of the tabular document
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
			
			If BinLocationWarehousingIsUsed Then
				
				ZoneText = NStr("vi = 'Khu vực giao hàng:';
								|ru = 'Зона отгрузки:';
								|en = 'Outbound area:'; fa = 'ناحیه خروجی:';
								|it = 'Area di spedizione:';
								|pl = 'Strefa wysyłki:';
								|tr = 'Yükleme alanı:'", Common.DefaultLanguageCode());
				ZonePresentation = SelectionByDocuments.ShipmentAreaPresentation;
				
			Else
				
				ZoneText = "";
				ZonePresentation = "";
				
			EndIf;
			
			FillPropertyValues(DocumentAttributes, SelectionByDocuments);
			
			HeaderDataStructure = New Structure;
			HeaderDataStructure.Insert("TitleText", 
					TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
			HeaderArea_.Parameters.Fill(HeaderDataStructure);
			
			If DisplayStamps Then
				HeaderArea_.Parameters.MarkingAttribute = "[M]";
			EndIf; 
			
			SpreadsheetDocument.Put(HeaderArea_);
			
			If ValueIsFilled(SelectionByDocuments.RecipientPresentation1) Then //if not moving or posting
				ScopeOfApplication_5.Parameters.Fill(SelectionByDocuments);
				SpreadsheetDocument.Put(ScopeOfApplication_5);		
			EndIf;
			
			SectionHeader.Parameters.WarehousePresentation_			=
				WarehousesServer.GetWarehousePresentation(SelectionByDocuments.WarehousePresentation_,SelectionByDocuments.PresentationOfPremises);
			SectionHeader.Parameters.ZoneText 					= ZoneText;
			SectionHeader.Parameters.ShipmentAreaPresentation	= ZonePresentation;
			
			Counter = 0;
			SubmissionOfOrders = "";
			FirstOrder = True;
			While SelectionOfOrders.FindNext(New Structure("Ref", SelectionByDocuments.Ref)) Do
				
				DocumentAttributes.Date          = SelectionOfOrders.Order_Date;
				DocumentAttributes.Number         = SelectionOfOrders.OrderNumber__;
				DocumentAttributes.Prefix       = SelectionOfOrders.OrderPrefix_;
				DocumentAttributes.Presentation = SelectionOfOrders.ReferenceOrderPresentation;
				
				PresentationOfOrder = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes);
				
				If Not FirstOrder Then
					SubmissionOfOrders = SubmissionOfOrders + ", ";		
				EndIf;
				
				FirstOrder = False;
				
				SubmissionOfOrders = SubmissionOfOrders + PresentationOfOrder;
				
				Counter = Counter + 1;
				
			EndDo;
			
			OrderHeader = "";
			If Counter > 1 Then 
				OrderHeader = NStr("vi = 'Lệnh:';
									|ru = 'Распоряжения:';
									|en = 'References:'; fa = 'مراجع:';
									|it = 'Disposizioni:';
									|pl = 'Zamówienia:';
									|tr = 'Emir:'", Common.DefaultLanguageCode());
			Else
				OrderHeader = NStr("vi = 'Lệnh:';
									|ru = 'Распоряжение:';
									|en = 'Reference:'; fa = 'مرجع:';
									|it = 'Disposizione:';
									|pl = 'Zamówienie:';
									|tr = 'Emir:'", Common.DefaultLanguageCode());
			EndIf;
			
			SectionHeader.Parameters.SubmissionOfOrders = SubmissionOfOrders;
			SectionHeader.Parameters.OrderHeader     = OrderHeader;
						
			SectionHeader.Parameters.DateOfShipment	= SelectionByDocuments.DateOfShipment;
					
			SpreadsheetDocument.Put(SectionHeader);
			
			If SelectionByDocuments.ShipmentUnderTransportationJob Then
				
				DocumentAttributes.Date          = SelectionByDocuments.TransportationTaskDate;
				DocumentAttributes.Number         = SelectionByDocuments.TransportationTaskNumber;
				DocumentAttributes.Prefix       = "";
				DocumentAttributes.Presentation = SelectionByDocuments.TransportationJobPresentation;
				
				TransportTaskArea.Parameters.PresentationOfTransportationOrder	 =
					TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes);				
				TransportTaskArea.Parameters.DeliveryProcedure = SelectionByDocuments.DeliveryProcedure;
			
				SpreadsheetDocument.Put(TransportTaskArea);
				
			EndIf;
			
			// Output the header of the nomenclature table
			SpreadsheetDocument.Put(Area_TableHeader);
			
			TotalItems_1 = 0;
			
			// Let's create a tabular document for an unloaded item
			DoNotShipTabularDocument = New SpreadsheetDocument;
			TotalItemsDoNotShip = 0;
			
			SelectionBasedOnDonTShipParameter = TSSamplingByLinks.Select(QueryResultIteration.ByGroups);
			
			While SelectionBasedOnDonTShipParameter.Next() Do
				
				SamplingTSFromPackingLists = SelectionBasedOnDonTShipParameter.Select(QueryResultIteration.ByGroups);
				
				While SamplingTSFromPackingLists.Next() Do
					
					SamplingByTSProduct = SamplingTSFromPackingLists.Select(QueryResultIteration.ByGroups);
					
					While SamplingByTSProduct.Next() Do
						
						SamplingByTSCharacteristics = SamplingByTSProduct.Select(QueryResultIteration.ByGroups);
						While SamplingByTSCharacteristics.Next() Do
							SamplingByTSLines = SamplingByTSCharacteristics.Select(QueryResultIteration.ByGroups);
							
							FirstRow = True;
							StringOfPackages = "";
							StringQuantityOfPackages = "";
							UnitString = "";
							CountRow = "";
							
							While SamplingByTSLines.Next() Do
								
								If SamplingByTSProduct.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
									
									If FirstRow Then
										
										// Let's determine in which tabular document we output the nomenclature
										If SamplingByTSLines.DoNotShip = 0 Then
											TabularDocumentForStringOutput = SpreadsheetDocument;
											TotalItems_1 				 = TotalItems_1 + 1;
											LineNumber 					 = TotalItems_1;
										Else
											TabularDocumentForStringOutput = DoNotShipTabularDocument;
											TotalItemsDoNotShip 	 = TotalItemsDoNotShip + 1;
											LineNumber 					 = TotalItemsDoNotShip;
										EndIf;
										
										AreaTableRow.Parameters.Fill(SamplingByTSLines);
										AreaTableRow.Parameters.Fill(New Structure("LineNumber", LineNumber));
										
										If DisplayPackingLists Then
											AreaTableRow.Parameters.PackingListParent = SamplingByTSLines.PackingListParentCode; 
										EndIf;
										
										If OutputCodes Then
											AreaTableRow.Parameters.SKU = SamplingByTSLines[NameOfCodeColumn];
										EndIf;
										
										TheStructureOfTheSearch = New Structure;
										TheStructureOfTheSearch.Insert("Ref", SamplingByTSLines.Ref);
										TheStructureOfTheSearch.Insert("Products", SamplingByTSLines.Products);
										TheStructureOfTheSearch.Insert("Characteristic", SamplingByTSLines.Characteristic);
										TheStructureOfTheSearch.Insert("DoNotShip", SamplingByTSLines.DoNotShip);
										TheStructureOfTheSearch.Insert("PackingListParent", SamplingByTSLines.PackingListParent);
										
										SeriesString = "";
										While SelectionBySeries.FindNext(TheStructureOfTheSearch) Do
											SeriesString = SeriesString + SelectionBySeries.BatchPresentation + ", ";
										EndDo;
										
										If StrLen(SeriesString) <> 0 Then
											SeriesString = Left(SeriesString, StrLen(SeriesString) - 2);
										EndIf;
										
										AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
										AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
										
										If DisplayStamps And SamplingByTSLines.MarkedProducts Then
											AreaTableRow.Parameters.MarkingAttribute = "[M]";
										Else	
											AreaTableRow.Parameters.MarkingAttribute = "";
										EndIf; 
										
										AreaTableRow.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
											SamplingByTSLines.ProductPresentation,
											SamplingByTSLines.CharacteristicPresentation,
											, // Package
											SeriesString,
											AdditionalParametersProductPresentation);
										
										FirstRow = False;
										
										ProductWithSeriesInstances = True;
										
									EndIf;
									
									If DisplayingPackages Then
										StringOfPackages = StringOfPackages + SamplingByTSLines.PresentationOfPackingUnit + Chars.LF;
										StringQuantityOfPackages = StringQuantityOfPackages + SamplingByTSLines.NumberOfPackages + Chars.LF;
									EndIf;
									
									UnitString = UnitString + SamplingByTSLines.PresentationOfBasicUnitOfMeasure + Chars.LF;
									CountRow = CountRow + SamplingByTSLines.Count + Chars.LF;
									
								Else
									// Let's determine in which tabular document we output the nomenclature
									If SamplingByTSLines.DoNotShip = 0 Then
										TabularDocumentForStringOutput = SpreadsheetDocument;
										TotalItems_1 				 = TotalItems_1 + 1;
										LineNumber 					 = TotalItems_1;
									Else
										TabularDocumentForStringOutput = DoNotShipTabularDocument;
										TotalItemsDoNotShip 	 = TotalItemsDoNotShip + 1;
										LineNumber 					 = TotalItemsDoNotShip;
									EndIf;
									
									AreaTableRow.Parameters.Fill(SamplingByTSLines);
									AreaTableRow.Parameters.Fill(New Structure("LineNumber", LineNumber));
									
									If DisplayPackingLists Then
										AreaTableRow.Parameters.PackingListParent = SamplingByTSLines.PackingListParentCode; 
									EndIf;
									
									If OutputCodes Then
										AreaTableRow.Parameters.SKU = SamplingByTSLines[NameOfCodeColumn];
									EndIf;
									
									AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
									AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
									
									If DisplayStamps And SamplingByTSLines.MarkedProducts Then
										AreaTableRow.Parameters.MarkingAttribute = "[M]";
									Else	
										AreaTableRow.Parameters.MarkingAttribute = "";
									EndIf; 
									
									AreaTableRow.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
										SamplingByTSLines.ProductPresentation,
										SamplingByTSLines.CharacteristicPresentation,
										, // Package
										SamplingByTSLines.BatchPresentation,
										AdditionalParametersProductPresentation);
									
									TabularDocumentForStringOutput.Put(AreaTableRow);
									
									ProductWithSeriesInstances = False;
									
								EndIf;
								
							EndDo;
							
							If ProductWithSeriesInstances Then
								
								If DisplayingPackages Then
									AreaTableRow.Parameters.NumberOfPackages = StringQuantityOfPackages;
									AreaTableRow.Parameters.PresentationOfPackingUnit = StringOfPackages;
								EndIf;
								
								AreaTableRow.Parameters.Count = CountRow;
								AreaTableRow.Parameters.PresentationOfBasicUnitOfMeasure = UnitString;
								
								TabularDocumentForStringOutput.Put(AreaTableRow);
								
							EndIf;
							
						EndDo;
					EndDo;
					
				EndDo;
				
			EndDo;
			
			// Output the table's basement and captions
			SpreadsheetDocument.Put(TableBasementArea);
			
			TextOfResultingLine = NStr("vi = 'Tổng số mặt hàng: %TotalItems_1%';
										|ru = 'Всего наименований %TotalItems_1%';
										|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
										|it = 'Totale articoli %TotalItems_1%';
										|pl = 'Razem pozycji %TotalItems_1%';
										|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
			TextOfResultingLine = StrReplace(TextOfResultingLine, "%TotalItems_1%", TotalItems_1);
			SignatureArea.Parameters.TotalString = TextOfResultingLine;
			
			SignatureArea.Parameters.PresentationOfResponsible = PersonsTM.IndividualShortName(SelectionByDocuments.EmployeeResponsible, SelectionByDocuments.Date);
			
			SpreadsheetDocument.Put(SignatureArea);
			
			// Let's supplement the main tabular document with a table of non-downloadable nomenclature
			If TotalItemsDoNotShip > 0 Then
				
				// Let's output the title and header of the table of the non-loaded nomenclature
				TitleText = NStr("vi = 'Trong khu vực giao hàng cần đặt các mặt hàng sau';
								|ru = 'В зоне отгрузки необходимо оставить следующие позиции товаров';
								|en = 'The following goods items should be left in the outbound area'; fa = 'The following goods items should be left in the outbound area';
								|it = 'Nella area di spedizione, è necessario lasciare i seguenti articoli di merce';
								|pl = 'W strefie wysyłki należy zostawić następujące pozycje towarów';
								|tr = 'Aşağıdaki ürün pozisyonları yükleme alanında bırakılmalıdır'", Common.DefaultLanguageCode());
				AreaHeaderDoNotShip.Parameters.Fill(New Structure("TitleText", TitleText));
				SpreadsheetDocument.Put(AreaHeaderDoNotShip);
				
				SpreadsheetDocument.Put(Area_TableHeader);
								
				// Let's attach the table of non-downloadable nomenclature to the main tabular document
				SpreadsheetDocument.Put(DoNotShipTabularDocument);
				
				// Let's output the basement of the table of non-loaded nomenclature
				SpreadsheetDocument.Put(TableBasementArea);
				
			EndIf;
					
			#Region PrintingHierarchyOfPackingSheets
						
			If DisplayPackingLists
				And PackingSheetsOfDocument.FindRows(New Structure("ThereIsNesting", True)).Count() > 0 Then
				
				SpreadsheetDocument.Put(AreaHeaderTablesPackingLists);
				
				Documents.PackingList.RecursivelyDerivePackingListHierarchy(SpreadsheetDocument, AreaRowTablePackingLists, PackingSheetsOfDocument, SelectionByDocuments.Ref);
				
				SpreadsheetDocument.Put(AreaBasementTablePackingLists);
				
			EndIf;
			
			#EndRegion
		
			SpreadsheetDocument.EndRowAutoGrouping();
			
			PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
			
		EndDo;
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#EndIf

#Region Other

#If Not MobileStandaloneServer Then

Function OrderWarehousesDuringShipment(Val ReferenceOrder, Val Warehouse) Export
	Query = New Query;
	WarehouseArray = New Array;
	MetadataOfDocument = ReferenceOrder.Metadata(); // MetadataObjectDocument
	DocumentType = MetadataOfDocument.Name;
	Query.SetParameter("Ref", ReferenceOrder);
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	Goods.Warehouse AS Warehouse
	|FROM
	|	&DocumentDocumentTypeProducts AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|	AND Goods.Ref.Warehouse.IsFolder
	|
	|UNION ALL
	|
	|SELECT
	|	ReferenceOrder.Warehouse
	|FROM
	|	&DocumentDocumentType AS ReferenceOrder
	|WHERE
	|	ReferenceOrder.Ref = &Ref
	|	AND (NOT ReferenceOrder.Warehouse.IsFolder)
	|	AND ReferenceOrder.Warehouse.UseWarehouseManagemantSystemForGoodsIssue";
	
	Query.Text = StrReplace(Query.Text, "&DocumentDocumentTypeProducts", "Document." + DocumentType+".Goods");
	Query.Text = StrReplace(Query.Text, "&DocumentDocumentType", "Document." + DocumentType);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		WarehouseArray.Add(Selection.Warehouse);
	EndDo;
	If ValueIsFilled(Warehouse) 
		And WarehouseArray.Find(Warehouse) = Undefined Then
		WarehouseArray.Add(Warehouse);
	EndIf;
	Return WarehouseArray
EndFunction

// Parameters:
// 	Object - DocumentObject.GoodsIssueNote, FormDataStructure - 
Procedure SplitByPackagesForReference(Object) Export
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.LineNumber AS LineNumber,
	|	Table.Count AS Count,
	|	Table.Series AS Series
	|INTO RequestProductTable
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.PackingListParent = VALUE(Document.PackingList.EmptyRef)
	|	AND Table.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
	|	AND NOT Table.ThisIsAPackingList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Products AS Products,
	|	MIN(Table.LineNumber) AS LineNumber,
	|	CAST(Table.Products AS Catalog.Products).PackagingGroup AS PackagingGroup,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Series AS Series,
	|	SUM(Table.Count) AS Count
	|INTO ProductsTable
	|FROM
	|	RequestProductTable AS Table
	|
	|GROUP BY
	|	Table.Series,
	|	Table.Products,
	|	CAST(Table.Products AS Catalog.Products).PackagingGroup,
	|	Table.Characteristic,
	|	Table.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsTable.Products AS Products,
	|	ProductsTable.Count,
	|	ProductsTable.LineNumber AS LineNumber,
	|	ProductsTable.Characteristic AS Characteristic,
	|	ProductsTable.Series AS Series,
	|	ProductsTable.Purpose AS Purpose,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS QuantityPerPackage,
	|	ISNULL(ProductPackages.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick) AS Action
	|FROM
	|	ProductsTable AS ProductsTable
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (ProductsTable.Products = ProductPackages.Owner
	|				OR ProductsTable.PackagingGroup = ProductPackages.Owner)
	|			AND (NOT ProductPackages.DeletionMark)
	|			AND (ProductPackages.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem))
	|			AND (ProductPackages.PackageType <> VALUE(Enum.TypesOfItemsPackages.Unpacking))
	|			AND ProductsTable.Count >= &QueryTextPackagingFactor
	|
	|ORDER BY
	|	LineNumber,
	|	QuantityPerPackage DESC";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPackages",
			"ProductsTable.Products"));
	
	ProductsTable = Object.ShippedGoods.Unload();
	Query.SetParameter("Table",ProductsTable);
	
	LinesToDelete = New Array;
	
	Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	For Each RowOfTables In Object.ShippedGoods Do
		If RowOfTables.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick
			And Not ValueIsFilled(RowOfTables.PackingListParent) Then
			LinesToDelete.Add(RowOfTables);
		EndIf;
	EndDo;
	
	For Each ArrRow In LinesToDelete Do
		Object.ShippedGoods.Delete(ArrRow);
	EndDo;
	
	CurrentValues = New Structure;
	CurrentValues.Insert("LineNumber", Undefined);
	CurrentValues.Insert("Products", Undefined);
	CurrentValues.Insert("Characteristic", Undefined);
	CurrentValues.Insert("Purpose", Undefined);
	CurrentValues.Insert("Series", Undefined);
	
	Count = 0;
	
	While Selection.Next() Do
		
		If Selection.LineNumber <> CurrentValues.LineNumber Then
			
			If Count <> 0 Then
				NewRow = Object.ShippedGoods.Add();
				NewRow.Count = Count;
				NewRow.NumberOfPackages = Count;
				
				NewRow.Products = CurrentValues.Products;
				NewRow.Characteristic = CurrentValues.Characteristic;
				NewRow.Purpose = CurrentValues.Purpose;
				NewRow.Series = CurrentValues.Series;
				NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;
			EndIf;
			FillPropertyValues(CurrentValues, Selection);
			
			Count = Selection.Count;
			
		EndIf;
		
		If Not ValueIsFilled(Selection.Package) Then
			Continue;
		EndIf;
		
		QuantityPerDocument = Int(Count / Selection.QuantityPerPackage);
		
		If QuantityPerDocument > 0 Then
		
			NewRow = Object.ShippedGoods.Add();
			NewRow.Count = QuantityPerDocument * Selection.QuantityPerPackage;
			NewRow.NumberOfPackages = QuantityPerDocument;
			NewRow.Package = Selection.Package;
			
			NewRow.Products = CurrentValues.Products;
			NewRow.Characteristic = CurrentValues.Characteristic;
			NewRow.Purpose = CurrentValues.Purpose;
			NewRow.Series = CurrentValues.Series;
			NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;

			Count = Count - QuantityPerDocument * Selection.QuantityPerPackage;
		EndIf;
	EndDo;
	
	If Round(Count,3) <> 0 Then
		NewRow = Object.ShippedGoods.Add();
		NewRow.Count = Count;
		NewRow.NumberOfPackages = Count;
		
		NewRow.Products = CurrentValues.Products;
		NewRow.Characteristic = CurrentValues.Characteristic;
		NewRow.Purpose = CurrentValues.Purpose;	
		NewRow.Series = CurrentValues.Series;
		NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;
	EndIf;
	
	ProductsServer.SplitProductsByProductLocations(Object.ShippedGoods);
	
	Object.TotalNumberOfPackageItems = PackingListsServer.NumberOfSeatsWH(Object.ShippedGoods);

EndProcedure

// Parameters:
// 	Object - DocumentObject.GoodsIssueNote, FormDataStructure - 
Procedure FillInShippedGoodsByGoodsByOrders(Object) Export
	
	Object.ShippedGoods.Clear();
	
	For Each RowOfTables In Object.GoodsByReferences Do
		
		NewRow = Object.ShippedGoods.Add();
		FillPropertyValues(NewRow, RowOfTables);
		NewRow.NumberOfPackages = RowOfTables.Count;
		
		If GetFunctionalOption("UseGoodsIssueNoteStatuses", New Structure("Warehouse", Object.Warehouse)) Then
			NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;
		Else
			NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;
		EndIf;
		
	EndDo;
	
	ConvolutionColumns = "Products, Characteristic, Purpose, Series, BatchesIndicationStatus, ThisIsAPackingList,"
					 + "PackingListParent, PackingList, Package, Action";
	Sum_Columns   = "Count, NumberOfPackages";

	If TypeOf(Object) = Type("FormDataStructure") Then
		TableForConvolution = Object.ShippedGoods.Unload(); // ValueTable
		TableForConvolution.GroupBy(ConvolutionColumns, Sum_Columns);
		Object.ShippedGoods.Load(TableForConvolution);
	Else
		Object.ShippedGoods.GroupBy(ConvolutionColumns, Sum_Columns);
	EndIf;
	
	Object.TotalNumberOfPackageItems = PackingListsServer.NumberOfSeatsWH(Object.ShippedGoods);

EndProcedure

Procedure ChangeGoodsAccordingToOrdersForShippedGoods(Object,
			OutputMessages = False, FillInSelected = False) Export
	
	Selection = SelectionFromRequestForExceedingOrders(Object, FillInSelected);
	
	If Selection.Count() > 0 Then
		
		While Selection.Next() Do
			
			QuantityToDistribution = Selection.DiscrepancyWithOrder;
			
			If Selection.ThereIsLineOfOrders Then
				
				FilterConditions = New Structure("Products,Characteristic,Series,Purpose");
				FillPropertyValues(FilterConditions,Selection);
				
				FoundOrders_ = Object.GoodsByReferences.FindRows(FilterConditions);
				
				
				For Each ArrRow In FoundOrders_ Do
					
					If QuantityToDistribution > 0 Then
						If QuantityToDistribution >= ArrRow.Count Then
							QuantityToDistribution = QuantityToDistribution - ArrRow.Count;
							Object.GoodsByReferences.Delete(ArrRow);
						Else
							ArrRow.Count = ArrRow.Count - QuantityToDistribution;
							QuantityToDistribution = 0;
						EndIf;
					Else
						ArrRow.Count = ArrRow.Count - QuantityToDistribution; 
						QuantityToDistribution = 0;
					EndIf;
					
					If QuantityToDistribution = 0 Then
						Break;
					EndIf;
					
				EndDo;
			Else
				NewRow = Object.GoodsByReferences.Add();
				FillPropertyValues(NewRow, Selection);
				NewRow.Count = - QuantityToDistribution;
			EndIf;
		EndDo;
	ElsIf OutputMessages Then
		MessageText = NStr("vi = 'Việc điền phần bảng ""Hàng hóa theo lệnh"" tương đương với việc điền phần bảng ""Hàng hóa đang giao"". Không cần điền lại.';
							|ru = 'Заполнение табличной части ""Товары по распоряжениям"" соответствует заполнению табличной части ""Отгружаемые товары"". Перезаполнение не требуется.';
							|en = 'Table ""Goods by references"" is filled to match the table ""Shipped goods"". Refilling is not required.'; fa = 'Table ""Goods by references"" is filled to match the table ""Shipped goods"". Refilling is not required.';
							|it = 'Compilazione della tabella ""Merci in base alle disposizioni"" corrisponde alla compilazione della tabella ""Merci in spedizione"". Ricompilazione non è necessaria.';
							|pl = 'Wypełnienie sekcji tabelarycznej ""Wiersze pozycji wg zamówień"" odpowiada wypełnieniu części tabelarycznej ""Wiersze pozycji wysyłkowe"". Nie jest wymagane uzupełnianie.';
							|tr = '""Emirlere göre ürünler"" tablo bölümünün doldurulması, ""Sevk edilen ürünler"" tablo bölümünün doldurulmasına karşılık gelir. Yeniden doldurma gerekli değildir.'");
		Common.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

Function SelectionFromRequestForExceedingOrders(Object, FillInSelected = False) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsByReferences.Products AS Products,
	|	GoodsByReferences.Characteristic AS Characteristic,
	|	GoodsByReferences.Purpose AS Purpose,
	|	GoodsByReferences.Series AS Series,
	|	GoodsByReferences.Count AS Count
	|INTO GoodsByReferences
	|FROM
	|	&GoodsByReferences AS GoodsByReferences
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(ShippedGoods.Products AS Catalog.Products) AS Products,
	|	ShippedGoods.Characteristic AS Characteristic,
	|	ShippedGoods.Purpose AS Purpose,
	|	CASE
	|		WHEN ShippedGoods.BatchesIndicationStatus IN (10, 14)
	|			THEN ShippedGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	ShippedGoods.Count AS Count,
	|	ShippedGoods.NumberOfPackages AS NumberOfPackages,
	|	CAST(ShippedGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package
	|INTO ShippedGoodsAreIncomplete
	|FROM
	|	&ShippedGoods AS ShippedGoods
	|WHERE
	|	NOT ShippedGoods.ThisIsAPackingList
	|	AND ShippedGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShippedGoods.Products AS Products,
	|	ShippedGoods.Characteristic AS Characteristic,
	|	ShippedGoods.Purpose AS Purpose,
	|	ShippedGoods.Series AS Series,
	|	MAX(ShippedGoods.Package) AS Package
	|INTO GoodsShippedGrouped
	|FROM
	|	ShippedGoodsAreIncomplete AS ShippedGoods
	|WHERE
	|	ISNULL(ShippedGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	ShippedGoods.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////	
	|SELECT
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	ShippedGoods.Series,
	|	ShippedGoods.Count
	|INTO ShippedGoods
	|FROM
	|	ShippedGoodsAreIncomplete AS ShippedGoods
	|WHERE
	|	ISNULL(ShippedGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	ShippedGoods.Series,
	|	SUM(ShippedGoodsQuantity.NumberOfPackages) / ShippedGoods.Package.NumberOfPackages
	|FROM
	|	GoodsShippedGrouped AS ShippedGoods
	|		INNER JOIN ShippedGoodsAreIncomplete AS ShippedGoodsQuantity
	|		ON ShippedGoods.Products = ShippedGoodsQuantity.Products
	|			AND ShippedGoods.Characteristic = ShippedGoodsQuantity.Characteristic
	|			AND ShippedGoods.Series = ShippedGoodsQuantity.Series
	|			AND ShippedGoods.Purpose = ShippedGoodsQuantity.Purpose
	|			AND ShippedGoods.Package = ShippedGoodsQuantity.Package
	|
	|GROUP BY
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	ShippedGoods.Series,
	|	ShippedGoods.Package,
	|	ShippedGoods.Package.NumberOfPackages
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsByReferences.Products AS Products,
	|	GoodsByReferences.Characteristic AS Characteristic,
	|	GoodsByReferences.Purpose AS Purpose,
	|	GoodsByReferences.Series AS Series,
	|	TRUE AS LineOfOrders,
	|	0 AS QuantityShipped_,
	|	GoodsByReferences.Count AS QuantityByOrder_
	|INTO ProductsByDocument
	|FROM
	|	GoodsByReferences AS GoodsByReferences
	|
	|UNION ALL
	|
	|SELECT
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	ShippedGoods.Series,
	|	FALSE,
	|	ShippedGoods.Count,
	|	0
	|FROM
	|	ShippedGoods AS ShippedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllGoods.Products AS Products,
	|	AllGoods.Characteristic AS Characteristic,
	|	AllGoods.Purpose AS Purpose,
	|	AllGoods.Series AS Series,
	|	MAX(AllGoods.LineOfOrders) AS ThereIsLineOfOrders,
	|	CASE
	|		WHEN MAX(AllGoods.LineOfOrders)
	|			THEN CASE
	|					WHEN Goods.UnitOfMeasure.MeasuredValueType IN (&TypesOfMeasuredQuantities)
	|							AND &FillInSelected
	|						THEN CASE
	|								WHEN SUM(AllGoods.QuantityShipped_) - SUM(AllGoods.QuantityByOrder_) <= &AllowableVariance * SUM(AllGoods.QuantityByOrder_) / 100
	|									THEN SUM(AllGoods.QuantityByOrder_) - SUM(AllGoods.QuantityShipped_)
	|								ELSE -&AllowableVariance * SUM(AllGoods.QuantityByOrder_) / 100
	|							END
	|					ELSE SUM(AllGoods.QuantityByOrder_) - SUM(AllGoods.QuantityShipped_)
	|				END
	|		ELSE SUM(AllGoods.QuantityByOrder_) - SUM(AllGoods.QuantityShipped_)
	|	END AS DiscrepancyWithOrder
	|FROM
	|	ProductsByDocument AS AllGoods
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON AllGoods.Products = Goods.Ref
	|
	|GROUP BY
	|	AllGoods.Products,
	|	Goods.UnitOfMeasure.MeasuredValueType,
	|	AllGoods.Characteristic,
	|	AllGoods.Purpose,
	|	AllGoods.Series
	|
	|HAVING
	|	SUM(AllGoods.QuantityShipped_) <> SUM(AllGoods.QuantityByOrder_)";
	
	TypesOfMeasuredQuantities = Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits();
	QuantityTolerance = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	Query.SetParameter("TypesOfMeasuredQuantities", TypesOfMeasuredQuantities);
	Query.SetParameter("FillInSelected", FillInSelected);
	Query.SetParameter("AllowableVariance", QuantityTolerance);
	Query.SetParameter("ShippedGoods", Object.ShippedGoods.Unload());
	Query.SetParameter("GoodsByReferences", Object.GoodsByReferences.Unload());
	
	Return Query.Execute().Select();
	
EndFunction

// Parameters:
// 	Object - DocumentObject.GoodsIssueNote, FormDataStructure - 
Procedure FillInActionInLines(Object) Export
	
	If Object.Status = Enums.GoodsIssueNoteStatuses.Verified
		Or Object.Status = Enums.GoodsIssueNoteStatuses.ToShip
		Or Object.Status = Enums.GoodsIssueNoteStatuses.Shipped_ Then
		FoundRows = Object.ShippedGoods.FindRows(New Structure("Action",
		 														Enums.ActionsWithGoodsIssueNoteRows.Pick));
		
		For Each ArrRow In FoundRows Do
			ArrRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;
		EndDo;
		
	EndIf;
		
EndProcedure

Function PortableStrings(SourceObject_, StringsForReceiver)
	
	Result = New Structure("LinesToWrap,HasError", New Array, False);
	
	For Each ArrRow In StringsForReceiver Do
		
		CurrentRow = SourceObject_.ShippedGoods[ArrRow - 1];
		
		If Not WarehousesClientServer.LineOfSpendingOrderCanBeTransferredToAnotherOrder(CurrentRow) Then
			Result.HasError = True;
			Return Result;
		EndIf;
				
		Result.LinesToWrap.Add(CurrentRow);
		
		If CurrentRow.ThisIsAPackingList Then
			
			SubordinateRows = New Array;
			PackingListsServer.RecursivelyBypassSubordinateStrings(SourceObject_.ShippedGoods, CurrentRow.PackingList, ,SubordinateRows);
			CommonClientServer.SupplementArray(Result.LinesToWrap, SubordinateRows);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndIf

Function TextOfRequestForFillingInStatusesIndicatingSeriesOfProductsBeingShipped(Val SeriesSpecificationParameters)

	QueryText = 
    "SELECT
    |	Goods.Action,
	|	Goods.Products,
	|	Goods.Series,
	|	Goods.Count,
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
    |							WHEN Goods.Count > 0
    |									AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
    |								THEN CASE
    |										WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
    |											THEN 14
    |										ELSE 10
    |									END
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
    |										WHEN Goods.Count > 0
    |												AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
    |											THEN 6
    |										ELSE 5
    |									END
	|							ELSE CASE
	|									WHEN Goods.Count > 0
	|												AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|										THEN 8
	|									WHEN &OrderPreparation
	|										THEN 27
    |									ELSE 7
    |								END
    |						END
    |				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
    |						AND (BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentToCustomer
    |								AND &ShipmentToCustomer
    |							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnRetailShipment
    |								AND &RetailShipment
    |							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenShippingComponentsForAssembly
    |								AND &ShipComponentsForAssembly
    |							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenShippingKitsForDisassembly
    |								AND &ShipSetsForDisassembly
    |							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentForInternalNeeds
    |								AND &ShipmentForInternalNeeds
    |							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentByReturnToVendor
    |								AND &ShipmentUnderReturnToVendor
    |							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentByTransfer
    |								AND &ShipmentByTransfer)
    |					THEN CASE
    |							WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
    |								THEN CASE
    |										WHEN Goods.Count > 0
    |												AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
    |											THEN 4
    |										WHEN Goods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
    |												AND (NOT &UseBinLocationWarehousing
    |													OR &UseBinLocationWarehousing
    |														AND (&SelectionPlanning
    |															OR &OrderPreparation))
    |											THEN 0
    |										ELSE 3
    |									END
    |							ELSE CASE
    |									WHEN Goods.Count > 0
    |											AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
    |											AND Goods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
    |										THEN 2
    |									WHEN Goods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
    |										THEN 1
    |									WHEN Goods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.EmptyRef) 
    |										THEN 1
    |									ELSE 0
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
    |		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
    |			AND Goods.Products.ProductKind = BatchAccountingPolicies.Ref
    |;
    |
    |////////////////////////////////////////////////////////////////////////////////
    |SELECT
    |	StatusTable.LineNumber AS LineNumber,
    |	StatusTable.BatchesIndicationStatus AS BatchesIndicationStatus
    |FROM
    |	StatusTable AS StatusTable
    |WHERE
    |	StatusTable.BatchesIndicationStatus <> StatusTable.OldStatusOfSpecifyingSeries
    |
    |ORDER BY
    |	LineNumber";
    
    If SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined 
    	And SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages" Then
    	QueryText = StrReplace(QueryText,
    								"Goods.Count,",
    								"Goods.NumberOfPackages AS Count,")
    EndIf;
    
    Return QueryText;

EndFunction

Function TextOfRequestToFillInStatusesForSpecifyingProductSeriesByOrder(Val SeriesSpecificationParameters)
    
	Var QueryText;
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Series,
	|	Goods.Count,
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
	|							WHEN Goods.Count > 0
	|									AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN CASE
	|										WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|											THEN 14
	|										ELSE 10
	|									END
	|							ELSE CASE
	|									WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|										THEN 13
	|									ELSE 9
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
	|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND (CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusTable.LineNumber AS LineNumber,
	|	StatusTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	StatusTable AS StatusTable
	|WHERE
	|	StatusTable.BatchesIndicationStatus <> StatusTable.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

#EndRegion

#EndRegion

#EndIf
